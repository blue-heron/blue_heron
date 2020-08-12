defmodule Bluetooth.HCI.Transport.UART do
  @moduledoc """
  > The objective of this HCI UART Transport Layer is to make it possible to use the Bluetooth HCI
  > over a serial interface between two UARTs on the same PCB. The HCI UART Transport Layer
  > assumes that the UART communication is free from line errors.

  Reference: Version 5.0, Vol 4, Part A, 1
  """

  use GenServer
  alias Circuits.UART
  alias Bluetooth.HCI.Transport.UART.Framing

  @behaviour Bluetooth.HCI.Transport
  defstruct recv: nil,
            uart_pid: nil,
            uart_opts: [],
            device: [],
            init_commands: []

  @impl Bluetooth.HCI.Transport
  def init_commands(%Bluetooth.HCI.Transport.UART{init_commands: init_commands}),
    do: init_commands

  @impl Bluetooth.HCI.Transport
  def start_link(%Bluetooth.HCI.Transport.UART{} = config, recv) when is_function(recv, 1) do
    GenServer.start_link(__MODULE__, %{config | recv: recv})
  end

  @impl Bluetooth.HCI.Transport
  def send_command(pid, command) when is_binary(command) do
    GenServer.call(pid, {:send_command, command})
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
  def handle_call({:send_command, message}, _from, %{uart_pid: uart_pid} = state) do
    {:reply, :ok == UART.write(uart_pid, <<1>> <> message), state}
  end

  @impl GenServer
  def handle_info({:circuits_uart, _dev, msg}, state) do
    state.recv.(msg)
    {:noreply, state}
  end
end
