defmodule BlueHeron.HCI.Transport.UART do
  @moduledoc """
  > The objective of this HCI UART Transport Layer is to make it possible to use the Bluetooth HCI
  > over a serial interface between two UARTs on the same PCB. The HCI UART Transport Layer
  > assumes that the UART communication is free from line errors.

  Reference: Version 5.0, Vol 4, Part A, 1
  """

  use GenServer
  require Logger
  alias Circuits.UART
  alias BlueHeron.HCI.Transport.UART.Framing

  @hci_command_packet 0x01
  @hci_acl_packet 0x02

  def start_link(args) do
    GenServer.start_link(__MODULE__, args)
  end

  @doc "Send binary HCI data"
  @spec send_command(GenServer.server(), binary()) :: :ok | {:error, term()}
  def send_command(pid, command) when is_binary(command) do
    GenServer.call(pid, {:send, [<<@hci_command_packet::8>>, command]})
  end

  @doc "Send binary ACL data"
  @spec send_acl(GenServer.server(), binary()) :: :ok | {:error, term()}
  def send_acl(pid, acl) when is_binary(acl) do
    GenServer.call(pid, {:send, [<<@hci_acl_packet::8>>, acl]})
  end

  @doc "Flush buffers"
  @spec flush(GenServer.server()) :: :ok
  def flush(pid) do
    GenServer.call(pid, :flush)
  end

  ## Server Callbacks

  @impl GenServer
  def init(args) do
    uart_opts = Keyword.merge(args, active: true, framing: {Framing, []})
    device = Keyword.get(uart_opts, :device)
    {:ok, pid} = UART.start_link()
    send(self(), {:open, device, uart_opts})
    state = %{uart_pid: pid}
    {:ok, state}
  end

  @impl GenServer
  def handle_call({:send, command}, _from, %{uart_pid: uart_pid} = state) do
    {:reply, UART.write(uart_pid, command), state}
  end

  def handle_call(:flush, _from, %{uart_pid: uart_pid} = state) do
    {:reply, UART.flush(uart_pid), state}
  end

  @impl GenServer
  def handle_info({:open, device, opts}, state) when is_binary(device) and is_list(opts) do
    case UART.open(state.uart_pid, device, opts) do
      :ok ->
        Logger.info("Opened UART for HCI transport: #{device} #{inspect(opts)}")
        :ok

      error ->
        Logger.error("Failed to open UART for HCI transport: #{inspect(error)}")
    end

    {:noreply, state}
  end

  def handle_info({:open, _, _}, state) do
    Logger.error("Failed to open UART for HCI transport: no device configured")
    {:noreply, state}
  end

  def handle_info({:circuits_uart, _dev, msg}, state) do
    _ = BlueHeron.HCI.Transport.transport_data(msg)
    {:noreply, state}
  end
end
