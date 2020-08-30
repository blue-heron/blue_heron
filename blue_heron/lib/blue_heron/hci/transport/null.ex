defmodule BlueHeron.HCI.Transport.NULL do
  @moduledoc """
  Transport impl that can be used to mock out HCI commands
  """
  use GenServer
  require Logger
  alias BlueHeron.HCI.Transport.NULL

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
end
