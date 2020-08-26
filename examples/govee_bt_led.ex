defmodule Bluetooth.Example.GoveeBTLed do
  use GenServer
  require Logger

  alias Bluetooth.HCI.Command.ControllerAndBaseband

  alias Bluetooth.HCI.Event.{
    LEMeta.ConnectionComplete,
    DisconnectionComplete
  }

  @usb_config %Bluetooth.HCI.Transport.LibUSB{
    vid: 0x0BDA,
    pid: 0xB82C,
    init_commands: [
      %ControllerAndBaseband.WriteLocalName{name: "BLE Scan Test"}
    ]
  }

  @uart_config %Bluetooth.HCI.Transport.UART{
    device: "ttyACM0",
    uart_opts: [speed: 115_200],
    init_commands: []
  }

  # @connect_addr 0xA4C1389D1EAD

  @doc "Start a linked connection to the bulb"
  def start_link(transport_type, config \\ %{})

  def start_link(:uart, config) do
    GenServer.start_link(__MODULE__, struct(@uart_config, config), [])
  end

  def start_link(:usb, config) do
    GenServer.start_link(__MODULE__, struct(@usb_config, config), [])
  end

  @doc """
  Set the color of the bulb.

      iex> GoveBTLED.set_color(pid, 0xFFFFFF) # full white
      :ok
      iex> GoveBTLED.set_color(pid, 0xFF0000) # full red
      :ok
      iex> GoveBTLED.set_color(pid, 0x00FF00) # full green
      :ok
      iex> GoveBTLED.set_color(pid, 0x0000FF) # full blue
      :ok
  """
  def set_color(pid, rgb) do
    GenServer.call(pid, {:set_color, rgb})
  end

  @impl GenServer
  def init(config) do
    {:ok, ctx} = Bluetooth.transport(config)
    Bluetooth.add_event_handler(ctx)
    {:ok, conn} = Bluetooth.ATT.Client.start_link(ctx)
    {:ok, %{conn: conn, ctx: ctx}}
  end

  @impl GenServer

  def handle_info({:BLUETOOTH_EVENT_STATE, :HCI_STATE_WORKING}, state) do
    Bluetooth.hci_command(state.ctx, %Bluetooth.HCI.Command.LEController.SetScanEnable{
      le_scan_enable: true
    })

    {:noreply, state}
  end

  def handle_info(
        {:HCI_EVENT_PACKET,
         %Bluetooth.HCI.Event.LEMeta.AdvertisingReport{
           devices: [
             %Bluetooth.HCI.Event.LEMeta.AdvertisingReport.Device{
               address: addr,
               data: ["\tMinger" <> _]
             }
           ]
         }},
        state
      ) do
    Logger.info("Trying to connect to #{inspect(addr, base: :hex)}")
    :ok = Bluetooth.ATT.Client.create_connection(state.conn, peer_address: addr)
    {:noreply, state}
  end

  def handle_info({:HCI_EVENT_PACKET,_}, state) do
    {:noreply, state}
  end
  def handle_info({:HCI_ACL_DATA_PACKET,_}, state) do
    {:noreply, state}
  end

  def handle_info({Bluetooth.ATT.Client, _, %ConnectionComplete{}}, state) do
    Logger.info("Connection established")
    {:noreply, state}
  end

  def handle_info({Bluetooth.ATT.Client, _, %DisconnectionComplete{reason_name: reason}}, state) do
    Logger.warn("Connection dropped: #{reason}")
    {:noreply, state}
  end

  def handle_info({Bluetooth.ATT.Client, _, event}, state) do
    Logger.error("Unhandled BLE Event: #{inspect(event)}")
    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:set_color, rgb}, _from, state) do
    value = <<0x33, 0x5, 0x2, rgb::24, 0, rgb::24, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
    checksum = calculate_xor(value, 0)

    case Bluetooth.ATT.Client.write(state.conn, 0x0015, <<value::binary-19, checksum::8>>) do
      :ok ->
        Logger.info("Setting LED Color: ##{inspect(rgb, base: :hex)}")
        {:reply, :ok, state}

      :error ->
        Logger.info("Failed to set LED color")
        {:reply, {:error, :write}, state}
    end
  end

  defp calculate_xor(<<>>, checksum), do: checksum

  defp calculate_xor(<<x::8, rest::binary>>, checksum),
    do: calculate_xor(rest, :erlang.bxor(checksum, x))
end
