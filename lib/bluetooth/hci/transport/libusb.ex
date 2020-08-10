defmodule Bluetooth.HCI.Transport.LibUSB do
  use GenServer
  alias Bluetooth.HCI.Transport.LibUSB
  @behaviour Bluetooth.HCI.Transport

  defstruct vid: 0x0BDA,
            pid: 0xB82C,
            init_commands: []

  @impl Bluetooth.HCI.Transport
  def init_commands(%LibUSB{}) do
    []
  end

  @impl Bluetooth.HCI.Transport
  def start_link(%LibUSB{} = config, recv) when is_function(recv, 1) do
    GenServer.start_link(__MODULE__, {config, recv})
  end

  @impl Bluetooth.HCI.Transport
  def send_command(pid, command) when is_binary(command) do
    GenServer.call(pid, {:send_command, command})
  end

  @impl GenServer
  def init({_config, recv}) do
    name = {:spawn_executable, port_executable()}
    opts = [:binary, :nouse_stdio, :exit_status]
    port = :erlang.open_port(name, opts)
    {:ok, %{port: port, recv: recv}}
  end

  @impl true
  def handle_info({port, {:data, data}}, %{port: port, recv: recv} = state) do
    _ = recv.(data)
    {:noreply, state}
  end

  def handle_info({port, {:exit_status, status}}, %{port: port} = state) do
    {:stop, {:libusb_port_crash, status}, state}
  end

  @impl GenServer
  def handle_call({:send_command, packet}, _from, state) do
    {:reply, :erlang.port_command(state.port, packet), state}
  end

  defp port_executable(), do: Application.app_dir(:bluetooth, ["priv", "hci_transport_libusb"])
end
