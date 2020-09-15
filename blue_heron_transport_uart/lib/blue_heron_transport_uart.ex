defmodule BlueHeronTransportUART do
  @moduledoc """
  > The objective of this HCI UART Transport Layer is to make it possible to use the Bluetooth HCI
  > over a serial interface between two UARTs on the same PCB. The HCI UART Transport Layer
  > assumes that the UART communication is free from line errors.

  Reference: Version 5.0, Vol 4, Part A, 1
  """

  use GenServer
  require Logger
  alias Circuits.UART
  alias BlueHeronTransportUART.Framing

  @behaviour BlueHeron.HCI.Transport

  @hci_command_packet 0x01
  @hci_acl_packet 0x02

  defstruct recv: nil,
            uart_pid: nil,
            pin_ref: nil,
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

    bts = BlueHeron.BTS.decode_file!("/lib/firmware/ti-connectivity/TIInit_11.8.32.bts")

    {:ok, pid} = Circuits.UART.start_link()
    gpio_bt_en = 60
    {:ok, pin_ref} = Circuits.GPIO.open(gpio_bt_en, :output)
    Circuits.GPIO.write(pin_ref, 0)
    Process.sleep(5)
    Circuits.GPIO.write(pin_ref, 1)
    Process.sleep(200)

    :ok =
      Circuits.UART.open(pid, "ttyS3",
        # speed: 3_000_000,
        speed: 115_200,
        framing: Framing,
        active: false,
        flow_control: :hardware
      )

    state = %{config | uart_pid: pid, pin_ref: pin_ref}
    upload_firmware(bts.actions, state)
    {:ok, state}
  end
  def upload_firmware([%{type: :action_remarks, data: remark} | rest], state) do
    Logger.info("TEXAS Remark: #{remark}")
    upload_firmware(rest, state)
  end

  def upload_firmware([%{type: :action_send_command, data: <<1, _::binary>> = packet} | rest], state) do
    Logger.info("sending HCI packet: #{inspect(packet, base: :hex, limit: :infinity)}")
    :ok = Circuits.UART.write(state.uart_pid, packet)
    upload_firmware(rest, state)
  end

  def upload_firmware(
        [%{type: :action_wait_event, data: %{msec: timeout, wait_data: wait_data}} | rest],
        state
      ) do
    case Circuits.UART.read(state.uart_pid, timeout) do
      {:ok, ^wait_data} ->
        upload_firmware(rest, state)

      {:ok, bad} ->
        Logger.error(
          "Bad data: #{inspect(bad, base: :hex, limit: :infinity)}\nexpected: #{
            inspect(wait_data, limit: :infinity, base: :hex)
          }"
        )
        upload_firmware(rest, state)

      error ->
        error
    end
  end

  def upload_firmware([%{type: :action_serial, data: %{baud: baud, flow: flow}} | rest], state) do
    Logger.info("not sure what to do with action_serial: #{baud} #{flow}")
    # :ok = Circuits.UART.close(state.uart_pid)

    :ok =
      Circuits.UART.configure(state.uart_pid,
        speed: 3_000_000,
        framing: Framing,
        active: false,
        flow_control: :hardware
      )

    upload_firmware(rest, state)
  end

  def upload_firmware([], state) do
    :ok =
      Circuits.UART.configure(state.uart_pid,
        speed: 3_000_000,
        framing: Framing,
        active: true,
        flow_control: :hardware
      )
  end

  @impl GenServer
  def handle_call({:send, message}, _from, %{uart_pid: uart_pid} = state) do
    {:reply, :ok == UART.write(uart_pid, message), state}
  end

  @impl GenServer
  def handle_info({:circuits_uart, _dev, {:error, message}}, state) do
    Logger.error "HCI UART Transport error: #{inspect(message)}"
    {:noreply, state}
  end

  def handle_info({:circuits_uart, _dev, msg}, state) do
    state.recv.(msg)
    {:noreply, state}
  end
end
