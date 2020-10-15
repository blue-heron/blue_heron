defmodule BlueHeron.HCI.Transport.NULL do
  @moduledoc """
  Transport impl that can be used to mock out HCI commands

  Example:

      iex> BlueHeron.HCI.Transport.start_link(%BlueHeron.HCI.Transport.NULL{
      ...>  init_commands: [Harald.HCI.ControllerAndBaseband.reset()],
      ...>  replies: %{
      ...>    Harald.HCI.ControllerAndBaseband.reset() => "\\x0e\\x04\\x03\\x03\\x0c\\x00"
      ...> }})
  """
  use GenServer
  require Logger
  alias BlueHeron.HCI.Transport.NULL
  import BlueHeron.HCI.Serializable, only: [serialize: 1]

  @behaviour BlueHeron.HCI.Transport

  defstruct replies: %{},
            recv: nil,
            init_commands: []

  @impl BlueHeron.HCI.Transport
  def init_commands(%NULL{init_commands: init_commands}), do: init_commands

  @impl BlueHeron.HCI.Transport
  def start_link(%NULL{} = config, recv) when is_function(recv, 1) do
    GenServer.start_link(__MODULE__, %{config | recv: recv})
  end

  @impl BlueHeron.HCI.Transport
  def send_command(pid, command) when is_binary(command) do
    GenServer.call(pid, {:send_command, command})
  end

  @impl BlueHeron.HCI.Transport
  def send_acl(pid, acl) when is_binary(acl) do
    GenServer.call(pid, {:send_acl, acl})
  end

  @impl GenServer
  def init(config) do
    {:ok, config}
  end

  @impl GenServer
  def handle_call({:send_command, command}, _from, state) do
    send(self(), {:handle_out, command})
    {:reply, true, state}
  end

  @impl GenServer
  def handle_call({:send_acl, acl}, _from, state) do
    send(self(), {:handle_out, acl})
    {:reply, true, state}
  end

  @impl GenServer
  def handle_info({:handle_out, command}, state) do
    # attach a 0x04 here due to a bug in Harald's HCI deserialize function
    case state.replies[command] do
      %{} = reply ->
        {:ok, data} = serialize(reply)
        state.recv.(<<0x04, data::binary>>)

      reply when is_binary(reply) ->
        state.recv.(<<0x04, reply::binary>>)

      _ ->
        Logger.error("No reply for #{inspect(command, base: :hex, limit: :infinity)}")
    end

    {:noreply, state}
  end
end
