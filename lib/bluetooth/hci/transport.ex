defmodule Bluetooth.HCI.Transport do
  @moduledoc """
  Handles sending and receiving HCI binaries via
  a physical link that implements the callbacks in this module
  """

  @default_max_error_count 2

  defstruct errors: 0,
            pid: nil,
            monitor: nil,
            config: nil,
            init_commands: [],
            caller: nil,
            handlers: [],
            max_error_count: @default_max_error_count

  require Bluetooth.HCIDump.Logger, as: Logger

  @type config :: map()
  @type recv_fun :: (binary -> any())
  @callback start_link(config, recv_fun) :: GenServer.on_start()
  @callback send_command(GenServer.server(), binary()) :: boolean()
  @callback init_commands(config) :: [binary()]

  @behaviour :gen_statem

  @doc "Start a transport"
  @spec start_link(config) :: GenServer.on_start()
  def start_link(%_module{} = config) do
    :gen_statem.start_link(__MODULE__, config, [])
  end

  @doc """
  Send a command via the configured transport
  """
  @spec command(GenServer.server(), binary()) :: {:ok, map()} | {:error, binary()}
  def command(pid, packet) do
    :gen_statem.call(pid, {:send_command, packet})
  end

  @doc """
  Subscribe to HCI event messages
  """
  @spec add_event_handler(GenServer.server()) :: :ok
  def add_event_handler(transport) do
    :gen_statem.call(transport, :add_event_handler)
  end

  @impl :gen_statem
  def callback_mode(), do: :state_functions

  @impl :gen_statem
  def init(%_module{} = config) do
    data = %__MODULE__{config: config}
    actions = [{:next_event, :internal, :open_transport}]
    {:ok, :unopened, data, actions}
  end

  @doc false
  def unopened(:internal, :open_transport, %{config: %module{} = config} = data) do
    this = self()

    case module.start_link(config, &Kernel.send(this, {:hci_data, &1})) do
      {:ok, pid} ->
        goto_prepare(data, pid)

      {:error, {:already_started, pid}} ->
        goto_prepare(data, pid)

      {:error, reason} ->
        Logger.error("Failed to open transport #{module}: #{inspect(reason)}")
        actions = [{:next_event, :internal, :open_transport}]
        {:keep_state_and_data, actions}
    end
  end

  @doc false
  def prepare({:call, {pid, _} = from}, :add_event_handler, data) do
    IO.puts("#{inspect(pid)} subscribed to Bluetooth events")
    {:keep_state, %{data | handlers: [pid | data.handlers]}, [{:reply, from, :ok}]}
  end

  # postpone calls until init completes
  def prepare({:call, _from}, _call, _data) do
    {:keep_state_and_data, [:postpone]}
  end

  def prepare(
        :info,
        {:DOWN, monitor, :process, pid, reason},
        %{pid: pid, monitor: monitor} = data
      ) do
    Logger.error("Transport crash #{inspect(reason)}")
    goto_unopened(data)
  end

  def prepare(:info, {:hci_data, <<0x4, hci::binary>> = packet}, data) do
    Logger.hci_packet(:HCI_EVENT_PACKET, :in, hci)

    case handle_packet(packet, data) do
      {:ok, %Harald.HCI.Event.CommandComplete{}, data} ->
        actions = [{:next_event, :internal, :init}]
        {:keep_state, data, actions}

      {:ok, unexpected, data} ->
        Logger.warn("Unexpected HCI data: #{inspect(unexpected)}")
        {:keep_state, data, []}

      {:error, reason, data} ->
        Logger.warn("Could not decode init_command response: #{inspect(reason)}")
        {:keep_state, data, []}
    end
  end

  def prepare(:internal, :init, %{init_commands: []} = data) do
    Logger.info("Init commands completed successfully")
    for pid <- data.handlers, do: send(pid, {:BLUETOOTH_EVENT_STATE, :HCI_STATE_WORKING})
    {:next_state, :ready, data, []}
  end

  def prepare(
        :internal,
        :init,
        %{pid: pid, config: %module{}, init_commands: [command | rest]} = data
      ) do
    case module.send_command(pid, command) do
      true ->
        Logger.hci_packet(:HCI_COMMAND_DATA_PACKET, :out, command)
        {:keep_state, %{data | init_commands: rest}, []}

      false ->
        Logger.error("Init command: #{inspect(command)} failed")
        goto_unopened(data)
    end
  end

  def prepare(:state_timeout, :init_command, data) do
    Logger.error("Timeout executing Init commands")
    goto_unopened(data)
  end

  @doc false
  def ready({:call, from}, {:send_command, command}, %{config: %module{}, pid: pid} = data) do
    case module.send_command(pid, command) do
      true ->
        Logger.hci_packet(:HCI_COMMAND_DATA_PACKET, :out, command)
        {:keep_state, %{data | caller: from}}

      false ->
        goto_unopened(data)
    end
  end

  # TODO Use Elixir Registry for this maybe idk
  def ready({:call, {pid, _tag} = from}, :add_event_handler, data) do
    # When in the ready state, send the HCI_STATE_WORKING signal
    send(pid, {:BLUETOOTH_EVENT_STATE, :HCI_STATE_WORKING})
    actions = [{:reply, from, :ok}]
    data = %{data | handlers: [pid | data.handlers]}
    {:keep_state, data, actions}
  end

  def ready(:info, {:hci_data, <<0x4, hci::binary>> = packet}, data) do
    Logger.hci_packet(:HCI_EVENT_PACKET, :in, hci)

    case handle_packet(packet, data) do
      {:ok, %Harald.HCI.Event.CommandComplete{} = reply, data} ->
        actions = maybe_reply(data, {:ok, reply})
        {:keep_state, %{data | caller: nil}, actions}

      {:ok, _data, data} ->
        {:keep_state, data, []}

      {:error, _bin, data} ->
        {:keep_state, data, []}
    end
  end

  # uses Harald to do HCI deserialization.
  defp handle_packet(packet, data) do
    case Harald.HCI.deserialize(packet) do
      {:ok, reply} ->
        for pid <- data.handlers, do: send(pid, {:HCI_EVENT_PACKET, reply})
        {:ok, reply, data}

      {:error, unknown} ->
        {:error, unknown, data}
    end
  end

  defp maybe_reply(%{caller: nil}, _), do: []
  defp maybe_reply(%{caller: caller}, reply), do: [{:reply, caller, reply}]

  # state change funs

  defp goto_unopened(%{errors: error_count, max_error_count: error_count} = data) do
    case maybe_reply(data, {:error, :unopened}) do
      [] ->
        {:stop, :reached_max_error, data}

      replies ->
        {:stop_and_reply, :reached_max_error, data, replies}
    end
  end

  defp goto_unopened(data) do
    actions =
      maybe_reply(data, {:error, :unopened}) ++ [{:next_event, :internal, :open_transport}]

    {:next_state, :unopened, %{data | pid: nil, monitor: nil, errors: data.errors + 1}, actions}
  end

  # Handles the initialization of the module
  defp goto_prepare(%{config: %module{} = config} = data, pid) do
    monitor = Process.monitor(pid)
    init_commands = module.init_commands(config)
    actions = [{:next_event, :internal, :init}, {:state_timeout, 5000, :init_command}]

    {:next_state, :prepare, %{data | pid: pid, monitor: monitor, init_commands: init_commands},
     actions}
  end
end
