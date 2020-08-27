defmodule Bluetooth.ATT.Client do
  @moduledoc """
  Linked connection to a BLE device

  ## Events

  Recieved when a connection is established with the device.
  This value should be treated as opaque. It should be used as a "handle" to the
  BLE device. See `write/3` for more info.

      {Bluetooth.ATT.Client, pid, %Bluetooth.HCI.Event.LEMeta.ConnectionComplete{}}

  Recieved when a connection is established with the device. Should
  invalidate a previous connection established.

      {Bluetooth.ATT.Client, pid, %Bluetooth.HCI.Event.DisconnectComplete{}}

  """
  require Logger
  @behaviour :gen_statem

  alias Bluetooth.HCI.Command.{
    LEController.CreateConnection
  }

  alias Bluetooth.HCI.Event.{
    LEMeta.ConnectionComplete,
    DisconnectionComplete,
    CommandStatus
  }

  alias Bluetooth.{
    ACL,
    L2Cap,
    ATT.ExchageMTURequest,
    ATT.ExchageMTUResponse,
    # ATT.ReadByGroupTypeRequest,
    # ATT.ReadByGroupTypeResponse,
    ATT.WriteCommand,
    ATT.HandleValueNTF,
    ATT.ReadByGroupTypeResponse,
    ATT.ReadByTypeResponse
  }

  @create_connection %CreateConnection{
    connection_interval_max: 0x0018,
    connection_interval_min: 0x0008,
    connection_latency: 0x0004,
    initiator_filter_policy: 0,
    le_scan_interval: 0x0060,
    le_scan_window: 0x0030,
    max_ce_length: 0x0030,
    min_ce_length: 0x0002,
    own_address_type: 0,
    peer_address_type: 0,
    supervision_timeout: 0x0048
  }

  @type client :: GenServer.server()
  @type handle ::
          %ReadByGroupTypeResponse.AttributeData{}
          | %ReadByTypeResponse.AttributeData{}
          | 0..0xFFF

  @doc """
  Example:

    iex> {:ok, pid} = ATT.Client.start_link(%Bluetooth.Context{})
    {:ok, #PID<0.111.0>}

  See the Events portion of the moduledoc to see events that will be delivered
  to the calling processes mailbox
  """
  @spec start_link(Bluetooth.Context.t(), GenServer.options()) :: GenServer.on_start()
  def start_link(%Bluetooth.Context{} = context, opts \\ []) do
    :gen_statem.start_link(__MODULE__, context, opts)
  end

  @doc """
  Attempt to create a connection with a device
  Args should be a keyword list of fields that get passed to Bluetooth.HCI.Command.LEController.CreateConnection

    iex> ATT.Client.create_connection(pid, peer_address: 0xabcdefg)
    :ok
  """
  @spec create_connection(client(), Keyword.t()) :: :ok | {:error, any()}
  def create_connection(pid, args) do
    :gen_statem.call(pid, struct(@create_connection, args))
  end

  @doc """
  Write a value to a handle on a BLE device

    iex> ATT.Client.write(pid, %ATT.ReadByTypeResponse.AttributeData{handle: 0x15}, <<1, 2, 3, 4>>)
    :ok

    iex> ATT.Client.write(pid, %ATT.ReadByGroupTypeRequest.AttributeData{handle: <<uuid::binary-128>>}, <<1, 2, 3, 4>>)
    :ok

    iex> ATT.Client.write(pid, 0x15, <<1, 2, 3, 4>>)
    :ok
  """
  @spec write(client, handle, binary()) :: :ok | {:error, term()}
  def write(pid, handle, value)

  def write(pid, %{handle: handle}, value), do: write(pid, handle, value)

  def write(pid, handle, value) do
    :gen_statem.call(pid, {:write_value, handle, value})
  end

  @doc false
  def child_spec(opts) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, [opts]}
    }
  end

  @impl :gen_statem
  @doc false
  def callback_mode(), do: :state_functions

  @impl :gen_statem
  @doc false
  def init(ctx) do
    :ok = Bluetooth.add_event_handler(ctx)

    data = %{
      ctx: ctx,
      caller: nil,
      connection: nil,
      create_connection: nil,
      client_mtu: 1961,
      server_mtu: nil,
      starting_handle: 0x0001,
      attributes: []
    }

    {:ok, :wait_working, data, []}
  end

  @doc false
  def wait_working(:info, {:BLUETOOTH_EVENT_STATE, :HCI_STATE_WORKING}, data) do
    {:next_state, :ready, data}
  end

  def wait_working(:info, {:HCI_EVENT_PACKET, packet}, _data) do
    Logger.info("Unknown packet for state CONNECT: #{inspect(packet, base: :hex, pretty: true)}")
    :keep_state_and_data
  end

  def wait_working({:call, _from}, _call, _data), do: {:keep_state_and_data, [:postpone]}

  @doc false
  def ready({:call, from}, %CreateConnection{} = cmd, data) do
    actions = [{:next_event, :internal, :create_connection}]
    {:next_state, :connecting, %{data | caller: from, create_connection: cmd}, actions}
  end

  def ready({:call, _from}, {:write_value, _handle, _value}, data) do
    {:keep_state, data, [{:reply, {:error, :disconnected}}]}
  end

  # ignore all HCI packets in ready state
  def ready(:info, {:HCI_EVENT_PACKET, _}, _data), do: :keep_state_and_data

  @doc false
  def connecting(:internal, :create_connection, data) do
    Logger.info("Opening connection")

    case Bluetooth.hci_command(data.ctx, data.create_connection) do
      {:ok, _} ->
        {:keep_state, data, [{:reply, data.caller, :ok}]}

      error ->
        {:keep_state, data, [{:reply, data.caller, error}]}
    end
  end

  def connecting(:info, {:HCI_EVENT_PACKET, %ConnectionComplete{} = connection}, data) do
    Logger.info("Connection established")
    {pid, _} = data.caller
    send(pid, {__MODULE__, self(), connection})
    actions = [{:next_event, :internal, :exchange_mtu}]
    {:next_state, :connected, %{data | connection: connection}, actions}
  end

  def connecting(:info, {:HCI_EVENT_PACKET, %CommandStatus{status: 18} = error}, data) do
    Logger.error("Could not establish connection")
    {:stop, error, data}
  end

  # ignore all other HCI packets in connecting state
  def connecting(:info, {:HCI_EVENT_PACKET, _}, _data), do: :keep_state_and_data

  @doc false
  def connected({:call, from}, {:write_value, handle, value}, data) do
    acl = %ACL{
      handle: data.connection.connection_handle,
      flags: %{bc: 0, pb: 0},
      data: %L2Cap{cid: 0x4, data: %WriteCommand{handle: handle, data: value}}
    }

    case Bluetooth.acl(data.ctx, acl) do
      :ok ->
        {:keep_state, %{data | caller: from}, [{:reply, from, :ok}]}

      error ->
        {:keep_state, data, [{:reply, from, error}]}
    end
  end

  def connected(:internal, :exchange_mtu, data) do
    acl = %ACL{
      handle: data.connection.connection_handle,
      flags: %{bc: 0, pb: 0},
      data: %L2Cap{cid: 0x4, data: %ExchageMTURequest{client_rx_mtu: data.client_mtu}}
    }

    case Bluetooth.acl(data.ctx, acl) do
      :ok ->
        :keep_state_and_data

      error ->
        Logger.error("Failed to exchange MTU: #{inspect(error)}")
        :keep_state_and_data
    end
  end

  # def connected(:internal, :read_by_group_type, data) do
  #   acl = %ACL{
  #     handle: data.connection.connection_handle,
  #     flags: %{bc: 0, pb: 0},
  #     data: %L2Cap{
  #       cid: 0x4,
  #       data: %ReadByGroupTypeRequest{
  #         starting_handle: data.starting_handle,
  #         ending_handle: 0xFFFF,
  #         uuid: 0x2800
  #       }
  #     }
  #   }

  #   case Bluetooth.acl(data.ctx, acl) do
  #     :ok ->
  #       :keep_state_and_data

  #     error ->
  #       Logger.error("Failed to read by group type: #{inspect(error)}")
  #       :keep_state_and_data
  #   end
  # end

  # Reply to a caller if it exists, reconnect
  def connected(:info, {:HCI_EVENT_PACKET, %DisconnectionComplete{} = disconnect}, data) do
    actions = [
      {:reply, data.caller, {:error, disconnect}},
      {:next_event, :internal, :create_connection}
    ]

    {:next_state, :connecting, data, actions}
  end

  # ignore all other HCI packets in connected state
  def connected(:info, {:HCI_EVENT_PACKET, _}, _data), do: :keep_state_and_data

  def connected(
        :info,
        {:HCI_ACL_DATA_PACKET,
         %ACL{data: %L2Cap{cid: 4, data: %ExchageMTUResponse{server_rx_mtu: mtu}}}},
        data
      ) do
    Logger.info("Server MTU: #{mtu}")

    actions = [
      # {:next_event, :internal, :read_by_group_type}
    ]

    {:keep_state, %{data | server_mtu: mtu}, actions}
  end

  def connected(
        :info,
        {:HCI_ACL_DATA_PACKET, %ACL{data: %L2Cap{cid: 4, data: %HandleValueNTF{} = value}}},
        data
      ) do
    {pid, _} = data.caller
    send(pid, {__MODULE__, self(), value})
    :keep_state_and_data
  end

  # def connected(:info, {:HCI_ACL_DATA_PACKET, %ACL{data: %L2Cap{cid: 4, data: %ReadByGroupTypeResponse{} = response}}}, data) do
  #   {pid, _} = data.caller
  #   send pid, self(), {__MODULE__, response}
  #   {:keep_state, %{data | starting_handle: }}
  # end
end
