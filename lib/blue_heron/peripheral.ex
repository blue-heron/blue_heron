defmodule BlueHeron.Peripheral do
  @moduledoc """
  Handles management of advertising and GATT server

  ## Advertisement Data and Scan Response Data

  both `set_advertising_data` and `set_scan_response_data` take the same binary
  data as an argument. The format is called `AdvertisingData` or `AD` for short in
  the official BLE spec. The format is

    <<length, param, data::binary-size(byte_size(data))>>

  Where `param` can be one of many values defined in the official BLE spec suplement, and each `param`
  has it's own data. Both params have a hard limit of 31 bytes total.
  """

  use GenServer
  require Logger

  alias BlueHeron.HCI.Command.LEController.{
    SetAdvertisingParameters,
    SetAdvertisingData,
    SetScanResponseData,
    SetAdvertisingEnable
  }

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

  def set_advertising_parameters(params) do
    GenServer.call(__MODULE__, {:set_advertising_parameters, params})
  end

  def set_advertising_data(data) do
    GenServer.call(__MODULE__, {:set_advertising_data, data})
  end

  def set_scan_response_data(data) do
    GenServer.call(__MODULE__, {:set_scan_response_data, data})
  end

  def start_advertising() do
    GenServer.call(__MODULE__, :start_advertising)
  end

  def stop_advertising() do
    GenServer.call(__MODULE__, :stop_advertising)
  end

  @spec exchange_mtu(non_neg_integer()) :: :ok | {:error, term()}
  def exchange_mtu(server_mtu) do
    GenServer.call(__MODULE__, {:exchange_mtu, server_mtu})
  end

  @spec notify(Service.id(), Characteristic.id(), binary()) :: :ok | {:error, term()}
  def notify(service_id, charateristic_id, data) do
    GenServer.call(__MODULE__, {:notify, service_id, charateristic_id, data})
  end

  def add_service(%Service{} = service) do
    services = PropertyTable.get(BlueHeron.GATT, ["profile"], [])
    PropertyTable.put(BlueHeron.GATT, ["profile"], [service | services])
  end

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
      advertising: false,
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

    new_state =
      if state.connection do
        command = Disconnect.new(connection_handle: state.connection.handle)
        {:reply, _reply, new_state} = handle_command(command, state)
        new_state
      else
        state
      end

    gatt_server = GATT.Server.init(profile)
    {:noreply, %{new_state | gatt_server: gatt_server}}
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

    if state.advertising do
      Logger.info("Restarting advertising")
      command = SetAdvertisingEnable.new(advertising_enable: true)
      {:reply, _reply, new_state} = handle_command(command, state)
      {:noreply, %{new_state | connection: nil}}
    else
      {:noreply, %{state | connection: nil}}
    end
  end

  def handle_info({:HCI_EVENT_PACKET, %ConnectionUpdateComplete{} = pkt}, state) do
    Logger.info("ConnectionUpdateComplete: #{inspect(pkt)}")
    {:noreply, state}
  end

  def handle_info({:HCI_EVENT_PACKET, %LongTermKeyRequest{} = request}, state) do
    case SMP.long_term_key_request(request) do
      %{} = command ->
        {:reply, _reply, new_state} = handle_command(command, state)
        {:noreply, new_state}

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

  def handle_call({:set_advertising_parameters, params}, _from, state) do
    command = SetAdvertisingParameters.new(params)
    handle_command(command, state)
  end

  def handle_call({:set_advertising_data, data}, _from, state) do
    command = SetAdvertisingData.new(advertising_data: data)
    handle_command(command, state)
  end

  def handle_call({:set_scan_response_data, data}, _from, state) do
    command = SetScanResponseData.new(scan_response_data: data)
    handle_command(command, state)
  end

  def handle_call(:start_advertising, _from, state) do
    command = SetAdvertisingEnable.new(advertising_enable: true)
    {:reply, reply, new_state} = handle_command(command, state)
    {:reply, reply, %{new_state | advertising: true}}
  end

  def handle_call(:stop_advertising, _from, state) do
    command = SetAdvertisingEnable.new(advertising_enable: false)
    {:reply, reply, new_state} = handle_command(command, state)
    {:reply, reply, %{new_state | advertising: false}}
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
        {:reply, :ok, state}

      {:ok, %CommandComplete{return_parameters: %{status: error}}} ->
        {^error, reply, _} = BlueHeron.ErrorCode.to_atom(error)
        {:reply, reply, state}

      {:ok, %CommandStatus{status: 0x00}} ->
        {:reply, :ok, state}

      {:ok, %CommandStatus{status: error}} ->
        {^error, reply, _} = BlueHeron.ErrorCode.to_atom(error)
        {:reply, reply, state}
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
