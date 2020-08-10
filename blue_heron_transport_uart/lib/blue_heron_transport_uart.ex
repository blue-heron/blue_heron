defmodule BlueHeronTransportUART do
  @moduledoc """
  > The objective of this HCI UART Transport Layer is to make it possible to use the Bluetooth HCI
  > over a serial interface between two UARTs on the same PCB. The HCI UART Transport Layer
  > assumes that the UART communication is free from line errors.

  Reference: Version 5.0, Vol 4, Part A, 1
  """

  use GenServer
  alias Circuits.UART
  alias BlueHeronTransportUART.Framing

  @behaviour BlueHeron.HCI.Transport

  @hci_command_packet 0x01
  @hci_acl_packet 0x02

  defstruct recv: nil,
            uart_pid: nil,
            uart_opts: [],
            device: [],
            init_commands: []

  @impl BlueHeron.HCI.Transport
  def init_commands(%BlueHeronTransportUART{init_commands: init_commands}),
    do: init_commands

  @impl BlueHeron.HCI.Transport
  def start_link(%BlueHeronTransportUART{} = config, recv) when is_function(recv, 1) do
    GenServer.start_link(__MODULE__, %{config | recv: recv})
  end

  @impl BlueHeron.HCI.Transport
  def send_command(pid, command) when is_binary(command) do
    GenServer.call(pid, {:send, [<<@hci_command_packet::8>>, command]})
  end

  @impl BlueHeron.HCI.Transport
  def send_acl(pid, acl) when is_binary(acl) do
    GenServer.call(pid, {:send, [<<@hci_acl_packet::8>>, acl]})
  end

  ## Server Callbacks

  @impl GenServer
  def init(config) do
    {:ok, pid} = UART.start_link()
    uart_opts = Keyword.merge([active: true, framing: {Framing, []}], config.uart_opts)
    :ok = UART.open(pid, config.device, uart_opts)
    {:ok, %{config | uart_pid: pid}}
  end

  @impl GenServer
  def handle_call({:send, message}, _from, %{uart_pid: uart_pid} = state) do
    {:reply, :ok == UART.write(uart_pid, message), state}
  end

  @impl GenServer
  def handle_info({:circuits_uart, _dev, msg}, state) do
    state.recv.(msg)
    {:noreply, state}
  end
end
