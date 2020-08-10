defmodule BlueHeronTransportUSB do
  @moduledoc """
  Partially implements Volume 4 Part C of the Bluetooth Spec
  """

  use GenServer
  @behaviour BlueHeron.HCI.Transport

  require Logger

  @hci_command_packet 0x01
  @hci_acl_packet 0x02
  @log_message_packet 0xFC

  defstruct vid: 0,
            pid: 0,
            init_commands: []

  @impl BlueHeron.HCI.Transport
  def init_commands(%__MODULE__{init_commands: init_commands}) do
    init_commands
  end

  @impl BlueHeron.HCI.Transport
  def start_link(%__MODULE__{} = config, recv) when is_function(recv, 1) do
    GenServer.start_link(__MODULE__, {config, recv})
  end

  @impl BlueHeron.HCI.Transport
  def send_command(pid, command) when is_binary(command) do
    GenServer.call(pid, {:send, [<<@hci_command_packet::8>>, command]})
  end

  @impl BlueHeron.HCI.Transport
  def send_acl(pid, acl) when is_binary(acl) do
    GenServer.call(pid, {:send, [<<@hci_acl_packet::8>>, acl]})
  end

  @impl GenServer
  def init({%__MODULE__{} = config, recv}) do
    port =
      Port.open({:spawn_executable, port_executable()}, [
        {:args, open_args(config)},
        :binary,
        :exit_status,
        {:packet, 2}
      ])

    {:ok, %{port: port, recv: recv}}
  end

  defp open_args(%__MODULE__{vid: vid, pid: pid}) when vid > 0 and pid > 0 do
    ["open_by_vid_pid", to_string(vid), to_string(pid)]
  end

  defp open_args(_other), do: ["open_first"]

  @impl true
  def handle_info(
        {port, {:data, <<@log_message_packet, level_num, message::binary>>}},
        %{port: port} = state
      ) do
    Logger.log(level(level_num), ["BlueHeron(USB): ", message])
    {:noreply, state}
  end

  def handle_info({port, {:data, data}}, %{port: port, recv: recv} = state) do
    _ = recv.(data)
    {:noreply, state}
  end

  def handle_info({port, {:exit_status, status}}, %{port: port} = state) do
    {:stop, {:libusb_port_crash, status}, state}
  end

  @impl GenServer
  def handle_call({:send, packet}, _from, state) do
    {:reply, Port.command(state.port, packet), state}
  end

  defp port_executable() do
    Application.app_dir(:blue_heron_transport_usb, ["priv", "hci_transport"])
  end

  # See hci_transport.h for levels
  defp level(0), do: :error
  defp level(1), do: :warn
  defp level(2), do: :debug
end
