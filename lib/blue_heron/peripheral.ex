defmodule BlueHeron.Peripheral do
  @moduledoc """
  Handles management of advertising and GATT server
  """

  use GenServer
  require Logger

  alias BlueHeron.HCI.Command.LinkControl.{
    Disconnect
  }

  alias BlueHeron.HCI.Event.{
    CommandComplete,
    CommandStatus,
    DisconnectionComplete,
    EncryptionChange
  }

  alias BlueHeron.HCI.Event.LEMeta.{
    ConnectionComplete,
    LongTermKeyRequest,
    ConnectionUpdateComplete
  }

  alias BlueHeron.{ACL, L2Cap}

  alias BlueHeron.GATT
  alias BlueHeron.GATT.{Characteristic, Service}

  alias BlueHeron.SMP

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Exchange MTU with a connected central.
  """
  @spec exchange_mtu(non_neg_integer()) :: :ok | {:error, term()}
  def exchange_mtu(server_mtu) do
    GenServer.call(__MODULE__, {:exchange_mtu, server_mtu})
  end

  @doc """
  Send a notification to a connected central.
  """
  @spec notify(Service.id(), Characteristic.id(), binary()) :: :ok | {:error, term()}
  def notify(service_id, charateristic_id, data) do
    GenServer.call(__MODULE__, {:notify, service_id, charateristic_id, data})
  end

  @doc """
  Register a new service in the GATT.
  """
  @spec add_service(Service.t()) :: :ok
  def add_service(service) do
    services = PropertyTable.get(BlueHeron.GATT, ["profile"], [])
    PropertyTable.put(BlueHeron.GATT, ["profile"], [service | services])
  end

  @doc """
  Delete a service by it's ID.
  """
  @spec delete_service(Service.id()) :: :ok
  def delete_service(service_id) do
    services = PropertyTable.get(BlueHeron.GATT, ["profile"], [])

    new_services =
      Enum.reject(services, fn service ->
        service.id == service_id
      end)

    PropertyTable.put(BlueHeron.GATT, ["profile"], new_services)
  end

  @impl GenServer
  def init(_) do
    :ok = PropertyTable.subscribe(BlueHeron.GATT, ["profile"])
    profile = PropertyTable.get(BlueHeron.GATT, ["profile"], [])

    state = %{
      ready?: false,
      connection: nil,
      gatt_server: GATT.Server.init(profile)
    }

    :ok = BlueHeron.Registry.subscribe()
    {:ok, state}
  end

  @impl GenServer
  def handle_info(
        %PropertyTable.Event{table: BlueHeron.GATT, property: ["profile"], value: profile},
        state
      )
      when is_list(profile) do
    Logger.info("Rebuilding GATT")
    gatt_server = GATT.Server.init(profile)
    new_state = %{state | gatt_server: gatt_server}

    if new_state.connection do
      command = Disconnect.new(connection_handle: new_state.connection.handle)
      handle_command(command, new_state)
    else
      {:noreply, new_state}
    end
  end

  def handle_info({:BLUETOOTH_EVENT_STATE, :HCI_STATE_WORKING}, state) do
    {:noreply, %{state | ready?: true}}
  end

  def handle_info({:HCI_EVENT_PACKET, %ConnectionComplete{} = event}, state) do
    Logger.info("Peripheral connect #{event.connection_handle}")

    connection = %{
      peer_address: event.peer_address,
      peer_address_type: event.peer_address_type,
      handle: event.connection_handle
    }

    :ok = BlueHeron.SMP.set_connection(connection)

    {:noreply, %{state | connection: connection}}
  end

  def handle_info({:HCI_EVENT_PACKET, %DisconnectionComplete{} = pkt}, state) do
    Logger.warning("Peripheral Disconnect #{inspect(pkt.reason)}")
    :ok = BlueHeron.SMP.set_connection(nil)
    {:noreply, %{state | connection: nil}}
  end

  def handle_info({:HCI_EVENT_PACKET, %ConnectionUpdateComplete{} = pkt}, state) do
    Logger.info("ConnectionUpdateComplete: #{inspect(pkt)}")
    {:noreply, state}
  end

  def handle_info({:HCI_EVENT_PACKET, %LongTermKeyRequest{} = request}, state) do
    case SMP.long_term_key_request(request) do
      %{} = command ->
        handle_command(command, state)

      _ ->
        {:noreply, state}
    end
  end

  def handle_info({:HCI_EVENT_PACKET, %EncryptionChange{} = request}, state) do
    :ok = SMP.encryption_change(request)
    {:noreply, state}
  end

  def handle_info({:HCI_EVENT_PACKET, _}, state) do
    {:noreply, state}
  end

  def handle_info(
        {:HCI_ACL_DATA_PACKET, %ACL{handle: handle, data: %L2Cap{cid: 0x0004, data: request}}},
        state
      ) do
    Logger.info(
      "Peripheral GATT request: #{inspect(handle, base: :hex)}=> #{inspect(request, base: :hex)}"
    )

    {gatt_server, response} = GATT.Server.handle(state.gatt_server, request)

    if response do
      acl_response = build_l2cap_acl(handle, 0x0004, response)
      BlueHeron.HCI.Transport.buffer_acl(acl_response)
    end

    {:noreply, %{state | gatt_server: gatt_server}}
  end

  def handle_info(
        {:HCI_ACL_DATA_PACKET, %ACL{handle: handle, data: %L2Cap{cid: 0x0006, data: request}}},
        state
      ) do
    response = SMP.handle(request)

    if response do
      acl_response = build_l2cap_acl(handle, 0x0006, response)
      BlueHeron.HCI.Transport.buffer_acl(acl_response)
    end

    {:noreply, state}
  end

  def handle_info({:HCI_ACL_DATA_PACKET, acl}, state) do
    Logger.info("Unhandled ACL packet: #{inspect(acl)}")
    {:noreply, state}
  end

  @impl GenServer
  def handle_call(_call, _from, %{ready?: false} = state) do
    {:reply, {:error, :setup_incomplete}, state}
  end

  def handle_call({:exchange_mtu, _server_mtu}, _from, %{connection: nil} = state) do
    {:reply, {:error, :no_connection}, state}
  end

  def handle_call({:exchange_mtu, server_mtu}, _from, state) do
    {:ok, request} = GATT.Server.exchange_mtu(state.gatt_server, server_mtu)
    acl = build_l2cap_acl(state.connection.handle, 0x0004, request)
    reply = BlueHeron.HCI.Transport.buffer_acl(acl)
    {:reply, reply, state}
  end

  def handle_call(
        {:notify, _service_id, _characteristic_id, _notification_data},
        _from,
        %{connection: nil} = state
      ) do
    {:reply, {:error, :no_connection}, state}
  end

  def handle_call({:notify, service_id, characteristic_id, notification_data}, _from, state) do
    notif =
      GATT.Server.handle_value_notification(
        state.gatt_server,
        service_id,
        characteristic_id,
        notification_data
      )

    case notif do
      {:ok, result} ->
        acl = build_l2cap_acl(state.connection.handle, 0x0004, result)

        Logger.info("Sending notification: #{acl}")
        reply = BlueHeron.HCI.Transport.buffer_acl(acl)
        {:reply, reply, state}

      error ->
        Logger.error("Failed to send notification: #{inspect(error)}")
        {:reply, error, state}
    end
  end

  defp handle_command(command, state) do
    case BlueHeron.HCI.Transport.send_hci(command) do
      {:ok, %CommandComplete{return_parameters: %{status: 0}}} ->
        {:noreply, state}

      {:ok, %CommandComplete{return_parameters: %{status: _error}}} ->
        {:noreply, state}

      {:ok, %CommandStatus{status: 0x00}} ->
        {:noreply, state}

      {:ok, %CommandStatus{status: _error}} ->
        {:noreply, state}
    end
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
