defmodule BlueHeron.Wilink8 do
  require Logger

  def init do
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
        framing: BlueHeronTransportUART.Framing,
        active: false,
        flow_control: :hardware
      )

    state = %{pin_ref: pin_ref, pid: pid}
    upload(bts.actions, state)
  end

  def upload([%{type: :action_remarks, data: remark} | rest], state) do
    Logger.info("TEXAS Remark: #{remark}")
    upload(rest, state)
  end

  def upload([%{type: :action_send_command, data: <<1, _::binary>> = packet} | rest], state) do
    Logger.info("sending HCI packet: #{inspect(packet, base: :hex, limit: :infinity)}")
    :ok = Circuits.UART.write(state.pid, packet)
    upload(rest, state)
  end

  def upload(
        [%{type: :action_wait_event, data: %{msec: timeout, wait_data: wait_data}} | rest],
        state
      ) do
    case Circuits.UART.read(state.pid, timeout) do
      {:ok, ^wait_data} ->
        upload(rest, state)

      {:ok, bad} ->
        Logger.error(
          "Bad data: #{inspect(bad, base: :hex, limit: :infinity)}\nexpected: #{
            inspect(wait_data, limit: :infinity, base: :hex)
          }"
        )
        upload(rest, state)

      error ->
        error
    end
  end

  def upload([%{type: :action_serial, data: %{baud: baud, flow: flow}} | rest], state) do
    Logger.info("not sure what to do with action_serial: #{baud} #{flow}")
    # :ok = Circuits.UART.close(state.pid)

    :ok =
      Circuits.UART.configure(state.pid,
        speed: 3_000_000,
        framing: BlueHeronTransportUART.Framing,
        active: false,
        flow_control: :hardware
      )

    upload(rest, state)
  end

  def upload([], state) do
    BlueHeron.transport(%BlueHeronTransportUART{device: "ttyS3", uart_pid: state.pid, uart_opts: [
      speed: 3_000_000,
      framing: BlueHeronTransportUART.Framing,
      active: true,
      flow_control: :hardware
    ]})
  end
end
