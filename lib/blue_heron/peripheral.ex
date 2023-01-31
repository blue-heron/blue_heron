defmodule BlueHeron.Peripheral do
  require Logger

  alias BlueHeron.HCI.Command.LEController.{
    SetAdvertisingParameters,
    SetAdvertisingData,
    SetAdvertisingEnable
  }

  alias BlueHeron.HCI.Command.LinkControl.{
    AuthenticationRequested,
    SetConnectionEncryption,
    Disconnect
  }

  alias BlueHeron.HCI.Event.{
    CommandComplete,
    CommandStatus,
    NumberOfCompletedPackets,
    DisconnectionComplete,
    EncryptionChange
  }

  alias BlueHeron.HCI.Event.LEMeta.{ConnectionComplete, LongTermKeyRequest}

  alias BlueHeron.{ACL, L2Cap}

  alias BlueHeron.GATT
  alias BlueHeron.GATT.{Characteristic, Service}

  alias BlueHeron.SMP

  @behaviour :gen_statem

  defstruct [:ctx, :bd_addr, :controlling_process, :gatt_handler, :gatt_server, :connection, :smp]

  def start_link(context, gatt_server) do
    :gen_statem.start_link(__MODULE__, [context, "/tmp/ble_keyfile", gatt_server, self()], [])
  end

  def start_link(context, keyfile, gatt_server) do
    :gen_statem.start_link(__MODULE__, [context, keyfile, gatt_server, self()], [])
  end

  def set_advertising_parameters(pid, params) do
    :gen_statem.call(pid, {:set_parameters, params})
  end

  def set_advertising_data(pid, data) do
    :gen_statem.call(pid, {:set_advertising_data, data})
  end

  def start_advertising(pid) do
    :gen_statem.call(pid, :start_advertising)
  end

  def stop_advertising(pid) do
    :gen_statem.call(pid, :stop_advertising)
  end

  def disconnect(pid) do
    :gen_statem.call(pid, :disconnect)
  end

  @doc """
  Send a HandleValueNotification packet

  * `pid` - the peripheral pid
  * `service_id` - the id used in the peripheral profile
  * `chararistic_id` - the id of the characistic on the service
  * `data` - binary data for the notification
  """
  @spec nofify(GenServer.server(), Service.id(), Characteristic.id(), binary()) ::
          :ok | {:error, term()}
  def nofify(pid, service_id, chararistic_id, data) do
    :gen_statem.call(pid, {:send_notification, service_id, chararistic_id, data})
  end

  @spec exchange_mtu(GenServer.server(), non_neg_integer()) :: :ok
  def exchange_mtu(pid, server_mtu) do
    :gen_statem.call(pid, {:exchange_mtu, server_mtu})
  end

  @impl :gen_statem
  def callback_mode(), do: :state_functions

  @impl :gen_statem
  def init([ctx, keyfile, gatt_handler, controlling_process]) do
    :ok = BlueHeron.add_event_handler(ctx)
    {:ok, smp} = SMP.start_link(ctx, keyfile)

    data = %__MODULE__{
      controlling_process: controlling_process,
      ctx: ctx,
      gatt_handler: gatt_handler,
      smp: smp
    }

    {:ok, :wait_working, data, []}
  end

  def wait_working(:info, {:BLUETOOTH_EVENT_STATE, :HCI_STATE_WORKING}, data) do
    {:next_state, :ready, data}
  end

  def wait_working(:info, {:HCI_EVENT_PACKET, _}, _data) do
    :keep_state_and_data
  end

  def wait_working({:call, _from}, _call, _data), do: {:keep_state_and_data, [:postpone]}

  def ready({:call, from}, {:set_parameters, params}, data) do
    command = SetAdvertisingParameters.new(params)

    {:ok, %CommandComplete{return_parameters: %{status: 0}}} =
      BlueHeron.hci_command(data.ctx, command)

    {:keep_state_and_data, [{:reply, from, :ok}]}
  end

  def ready({:call, from}, {:set_advertising_data, adv_data}, data) do
    command = SetAdvertisingData.new(advertising_data: adv_data)

    {:ok, %CommandComplete{return_parameters: %{status: 0}}} =
      BlueHeron.hci_command(data.ctx, command)

    {:keep_state_and_data, [{:reply, from, :ok}]}
  end

  def ready({:call, from}, :start_advertising, data) do
    command = SetAdvertisingEnable.new(advertising_enable: true)

    {:ok, %CommandComplete{return_parameters: %{status: 0}}} =
      BlueHeron.hci_command(data.ctx, command)

    {:next_state, :advertising, data, [{:reply, from, :ok}]}
  end

  def ready(:info, {:HCI_EVENT_PACKET, %CommandComplete{opcode: <<9, 16>>} = event}, data) do
    # Response from reading BD_ADDRESS
    SMP.set_bd_address(event.return_parameters.bd_addr)
    {:next_state, :ready, %{data | bd_addr: event.return_parameters.bd_addr}}
  end

  def ready(:info, {:HCI_EVENT_PACKET, _event}, _data) do
    :keep_state_and_data
  end

  def advertising({:call, from}, :stop_advertising, data) do
    command = SetAdvertisingEnable.new(advertising_enable: false)

    {:ok, %CommandComplete{return_parameters: %{status: 0}}} =
      BlueHeron.hci_command(data.ctx, command)

    {:next_state, :ready, data, [{:reply, from, :ok}]}
  end

  def advertising(:info, {:HCI_EVENT_PACKET, %ConnectionComplete{} = event}, data) do
    send(data.controlling_process, {__MODULE__, :connected})
    Logger.info("Peripheral connect #{event.connection_handle}")
    gatt_server = GATT.Server.init(data.gatt_handler)

    connection = %{
      peer_address: event.peer_address,
      peer_address_type: event.peer_address_type,
      handle: event.connection_handle
    }

    SMP.set_connection(connection)
    {:next_state, :connected, %{data | gatt_server: gatt_server, connection: connection}}
  end

  def advertising(:info, {:HCI_EVENT_PACKET, _event}, _data) do
    # TODO: Handle scan request, and maybe other events as well
    :keep_state_and_data
  end

  def advertising({:call, from}, :authenticate, _data) do
    {:keep_state_and_data, {:reply, from, {:error, :not_connected}}}
  end

  def connected({:call, from}, :disconnect, data) do
    command = Disconnect.new(connection_handle: data.connection.handle)
    {:ok, %CommandStatus{status: 0x00}} = BlueHeron.hci_command(data.ctx, command)
    {:keep_state_and_data, {:reply, from, :ok}}
  end

  def connected(
        {:call, from},
        {:send_notification, service_id, characteristic_id, notification_data},
        data
      ) do
    notif =
      GATT.Server.handle_value_notification(
        data.gatt_server,
        service_id,
        characteristic_id,
        notification_data
      )

    case notif do
      {:ok, result} ->
        acl = build_l2cap_acl(data.connection.handle, 0x0004, result)

        Logger.info(%{notif_acl: acl})

        r = BlueHeron.acl(data.ctx, acl)
        {:keep_state_and_data, {:reply, from, r}}

      error ->
        {:keep_state_and_data, {:reply, from, error}}
    end
  end

  def connected({:call, from}, {:exchange_mtu, server_mtu}, data) do
    {:ok, request} = GATT.Server.exchange_mtu(data.gatt_server, server_mtu)
    acl = build_l2cap_acl(data.connection.handle, 0x0004, request)
    r = BlueHeron.acl(data.ctx, acl)
    {:keep_state_and_data, {:reply, from, r}}
  end

  def connected(
        :info,
        {:HCI_ACL_DATA_PACKET, %ACL{handle: handle, data: %L2Cap{cid: 0x0004, data: request}}},
        data
      ) do
    Logger.info("Peripheral service discovery request: #{handle}=> #{inspect(request)}")
    {gatt_server, response} = GATT.Server.handle(data.gatt_server, request)

    if response do
      acl_response = build_l2cap_acl(handle, 0x0004, response)
      Process.sleep(100)
      BlueHeron.acl(data.ctx, acl_response)
    end

    {:keep_state, %{data | gatt_server: gatt_server}, []}
  end

  def connected(
        :info,
        {:HCI_ACL_DATA_PACKET, %ACL{handle: handle, data: %L2Cap{cid: 0x0006, data: request}}},
        data
      ) do
    response = SMP.handle(request)

    if response do
      acl_response = build_l2cap_acl(handle, 0x0006, response)
      Process.sleep(100)
      BlueHeron.acl(data.ctx, acl_response)
    end

    {:keep_state, data, []}
  end

  def connected(:info, {:HCI_ACL_DATA_PACKET, acl}, data) do
    Logger.info("Unhandled ACL packet: #{inspect(acl)} #{inspect(data)}")
    :keep_state_and_data
  end

  def connected(:info, {:HCI_EVENT_PACKET, %DisconnectionComplete{} = pkg}, data) do
    send(data.controlling_process, {__MODULE__, :disconnected})
    Logger.warn("Peripheral Disconnect #{inspect(pkg.reason)}")
    {:next_state, :ready, %{data | gatt_server: nil, connection: nil}}
  end

  def connected(:info, {:HCI_EVENT_PACKET, %CommandStatus{opcode: <<0x0406::little-16>>}}, _data) do
    # Ignore the notification that is generated we execute a Disconnect HCI command
    :keep_state_and_data
  end

  def connected(
        :info,
        {:HCI_EVENT_PACKET, %CommandComplete{return_parameters: %{status: 0}}},
        _data
      ) do
    # Ignore the notification that is generated when a command is executed with success
    :keep_state_and_data
  end

  def connected(:info, {:HCI_EVENT_PACKET, %NumberOfCompletedPackets{}}, _data) do
    # We still receive HCI_Number_Of_Completed_Packet events, ignore... (Flow
    # control is disabled)
    :keep_state_and_data
  end

  def connected(:info, {:HCI_EVENT_PACKET, %LongTermKeyRequest{} = request}, data) do
    command = SMP.long_term_key_request(request)

    if command do
      BlueHeron.hci_command(data.ctx, command)
    end

    {:keep_state, data, []}
  end

  def connected(:info, {:HCI_EVENT_PACKET, %EncryptionChange{} = request}, data) do
    SMP.encryption_change(request)
    {:keep_state, data, []}
  end

  def connected(:info, pkg, _data) do
    Logger.warn("Unhandled packet: #{inspect(pkg)}")
    :keep_state_and_data
  end

  defp build_l2cap_acl(handle, cid, payload) do
    %ACL{
      handle: handle,
      flags: %{bc: 0, pb: 0},
      data: %L2Cap{
        cid: cid,
        data: payload
      }
    }
  end
end
