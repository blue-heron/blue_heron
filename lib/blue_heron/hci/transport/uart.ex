# SPDX-FileCopyrightText: 2024 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
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

  @doc "Reconfigure UART settings (e.g., baud rate)"
  @spec configure(GenServer.server(), keyword()) :: :ok | {:error, term()}
  def configure(pid, opts) do
    GenServer.call(pid, {:configure, opts})
  end

  ## Server Callbacks

  @impl GenServer
  def init(args) do
    uart_opts = Keyword.merge(args, active: true)
    device = Keyword.get(uart_opts, :device)
    {:ok, pid} = UART.start_link()
    {:ok, framing_state} = Framing.init([])
    send(self(), {:open, device, uart_opts})
    state = %{uart_pid: pid, framing_state: framing_state}
    {:ok, state}
  end

  @impl GenServer
  def handle_call({:send, command}, _from, %{uart_pid: uart_pid} = state) do
    {:reply, UART.write(uart_pid, command), state}
  end

  def handle_call(:flush, _from, %{uart_pid: uart_pid} = state) do
    {:reply, UART.flush(uart_pid), state}
  end

  def handle_call({:configure, opts}, _from, %{uart_pid: uart_pid} = state) do
    {:reply, UART.configure(uart_pid, opts), state}
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

  def handle_info({:circuits_uart, _dev, msg}, state) when is_binary(msg) do
    Logger.debug(
      "UART rx #{byte_size(msg)}B: 0x#{Base.encode16(binary_part(msg, 0, min(byte_size(msg), 24)))}"
    )

    {:ok, frames, framing_state} = Framing.remove_framing(msg, state.framing_state)
    Enum.each(frames, &BlueHeron.HCI.Transport.transport_data/1)

    {:noreply, %{state | framing_state: framing_state}}
  end

  def handle_info({:circuits_uart, _dev, msg}, state) do
    Logger.warning("UART rx non-binary: #{inspect(msg)}")
    {:noreply, state}
  end
end
