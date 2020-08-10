defmodule Bluetooth.HCI.Transport.NULL do
  @moduledoc """
  Transport impl that can be used to mock out HCI commands

  Example:

      iex> Bluetooth.HCI.Transport.start_link(%Bluetooth.HCI.Transport.NULL{
      ...>  init_commands: [Harald.HCI.ControllerAndBaseband.reset()],
      ...>  replies: %{
      ...>    Harald.HCI.ControllerAndBaseband.reset() => "\\x0e\\x04\\x03\\x03\\x0c\\x00"
      ...> }})
  """
  use GenServer
  require Logger
  alias Bluetooth.HCI.Transport.NULL
  @behaviour Bluetooth.HCI.Transport

  defstruct replies: %{},
            recv: nil,
            init_commands: []

  @impl Bluetooth.HCI.Transport
  def init_commands(%NULL{init_commands: init_commands}), do: init_commands

  @impl Bluetooth.HCI.Transport
  def start_link(%NULL{} = config, recv) when is_function(recv, 1) do
    GenServer.start_link(__MODULE__, %{config | recv: recv})
  end

  @impl Bluetooth.HCI.Transport
  def send_command(pid, command) when is_binary(command) do
    GenServer.call(pid, {:send_command, command})
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
  def handle_info({:handle_out, command}, state) do
    # attach a 0x04 here due to a bug in Harald's HCI deserialize funciton
    case state.replies[command] do
      %{} = reply ->
        {:ok, binary} = Harald.HCI.serialize(reply)
        state.recv.(<<0x04>> <> binary)

      reply when is_binary(reply) ->
        state.recv.(<<0x04>> <> reply)

      _ ->
        Logger.error("No reply for #{inspect(command, base: :hex, limit: :infinity)}")
    end

    {:noreply, state}
  end
end
