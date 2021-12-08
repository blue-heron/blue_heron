defmodule BlueHeron.Peripheral do
  require Logger

  alias BlueHeron.HCI.Command.LEController.{
    SetAdvertisingParameters,
    SetAdvertisingData,
    SetAdvertisingEnable
  }

  alias BlueHeron.HCI.Event.{CommandComplete, DisconnectionComplete}
  alias BlueHeron.HCI.Event.LEMeta.ConnectionComplete

  alias BlueHeron.{ACL, L2Cap}

  alias BlueHeron.GATT

  @behaviour :gen_statem

  defstruct [:ctx, :controlling_process, :gatt_handler, :conn_handle, :gatt_server]

  def start_link(context, gatt_server) do
    :gen_statem.start_link(__MODULE__, [context, gatt_server, self()], [])
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

  @impl :gen_statem
  def callback_mode(), do: :state_functions

  @impl :gen_statem
  def init([ctx, gatt_handler, controlling_process]) do
    :ok = BlueHeron.add_event_handler(ctx)

    data = %__MODULE__{
      controlling_process: controlling_process,
      ctx: ctx,
      gatt_handler: gatt_handler
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
    gatt_server = GATT.Server.init(data.gatt_handler)

    {:next_state, :connected,
     %{data | gatt_server: gatt_server, conn_handle: event.connection_handle}}
  end

  def advertising(:info, {:HCI_EVENT_PACKET, _event}, _data) do
    # TODO: Handle scan request, and maybe other events as well
    :keep_state_and_data
  end

  def connected(
        :info,
        {:HCI_ACL_DATA_PACKET, %ACL{handle: handle, data: %L2Cap{cid: 0x0004, data: request}}},
        %{conn_handle: handle} = data
      ) do
    {gatt_server, response} = GATT.Server.handle(data.gatt_server, request)

    acl_response = %ACL{
      handle: data.conn_handle,
      flags: %{bc: 0, pb: 0},
      data: %L2Cap{
        cid: 0x0004,
        data: response
      }
    }

    BlueHeron.acl(data.ctx, acl_response)

    {:keep_state, %{data | gatt_server: gatt_server}, []}
  end

  def connected(:info, {:HCI_ACL_DATA_PACKET, acl}, _data) do
    Logger.info("Unhandled ACL packet: #{inspect(acl)}")
    :keep_state_and_data
  end

  def connected(:info, {:HCI_EVENT_PACKET, %DisconnectionComplete{}}, data) do
    {:next_state, :ready, %{data | gatt_server: nil, conn_handle: nil}}
  end
end
