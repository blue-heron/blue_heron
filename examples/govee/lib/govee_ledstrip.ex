defmodule GoveeLEDStrip do
  @moduledoc """
  Sample ATT application that can control the Govee H6125 LED Strip

  They can be found [here](https://www.amazon.com/MINGER-Dimmable-Changing-Equivalent-Multi-Color/dp/B07CL2RMR7/)
  """

  use GenServer
  require Logger

  alias BlueHeron.HCI.Command.{
    ControllerAndBaseband.WriteLocalName,
    LEController.SetScanEnable
  }

  alias BlueHeron.HCI.Event.{
    LEMeta.ConnectionComplete,
    DisconnectionComplete,
    LEMeta.AdvertisingReport,
    LEMeta.AdvertisingReport.Device
  }

  # Sets the name of the BLE device
  @write_local_name %WriteLocalName{name: "Govee Controller"}

  @default_uart_config %{
    device: "ttyACM0",
    uart_opts: [speed: 115_200],
    init_commands: [@write_local_name]
  }

  @default_usb_config %{
    vid: 0x0BDA,
    pid: 0xB82C,
    init_commands: [@write_local_name]
  }

  @doc """
  Start a linked connection to the bulb

  ## UART

      iex> {:ok, pid} = GoveeBulb.start_link(:uart, device: "ttyACM0")
      {:ok, #PID<0.111.0>}

  ## USB

      iex> {:ok, pid} = GoveeBulb.start_link(:usb)
      {:ok, #PID<0.111.0>}
  """
  def start_link(transport_type, config \\ %{})

  def start_link(:uart, config) do
    config = struct(BlueHeronTransportUART, Map.merge(@default_uart_config, config))
    GenServer.start_link(__MODULE__, config, [])
  end

  def start_link(:usb, config) do
    config = struct(BlueHeronTransportUSB, Map.merge(@default_usb_config, config))
    GenServer.start_link(__MODULE__, config, [])
  end

  @doc """
  Set the color of the bulb.

      iex> GoveeBulb.set_color(pid, 0xFFFFFF) # full white
      :ok
      iex> GoveeBulb.set_color(pid, 0xFF0000) # full red
      :ok
      iex> GoveeBulb.set_color(pid, 0x00FF00) # full green
      :ok
      iex> GoveeBulb.set_color(pid, 0x0000FF) # full blue
      :ok
  """
  def set_color(pid, rgb) do
    GenServer.call(pid, {:set_color, rgb})
  end

  @impl GenServer
  def init(config) do
    # Create a context for BlueHeron to operate with
    {:ok, ctx} = BlueHeron.transport(config)

    # Subscribe to HCI and ACL events
    BlueHeron.add_event_handler(ctx)

    # Start the ATT Client (this is what we use to read/write data with)
    {:ok, conn} = BlueHeron.ATT.Client.start_link(ctx)

    {:ok, %{conn: conn, ctx: ctx, connected?: false}}
  end

  @impl GenServer

  # Sent when a transport connection is established
  def handle_info({:BLUETOOTH_EVENT_STATE, :HCI_STATE_WORKING}, state) do
    # Enable BLE Scanning. This will deliver messages to the process mailbox
    # when other devices broadcast
    Logger.info("Scanning for devices")
    BlueHeron.hci_command(state.ctx, %SetScanEnable{le_scan_enable: true})
    {:noreply, state}
  end

  # Match for the Bulb.
  def handle_info(
        {:HCI_EVENT_PACKET,
         %AdvertisingReport{devices: [%Device{address: addr, data: ["\tihoment_H6125" <> _]}]}} =
          _arp,
        state
      ) do
    Logger.info("Trying to connect to GoveeLEDStrip #{inspect(addr, base: :hex)}")
    # Attempt to create a connection with it.
    :ok = BlueHeron.ATT.Client.create_connection(state.conn, peer_address: addr)
    {:noreply, state}
  end

  # ignore other HCI Events
  def handle_info({:HCI_EVENT_PACKET, _}, state), do: {:noreply, state}

  # ignore other HCI ACL data (ATT handles this for us)
  def handle_info({:HCI_ACL_DATA_PACKET, _}, state), do: {:noreply, state}

  # Sent when create_connection/2 is complete
  def handle_info({BlueHeron.ATT.Client, conn, %ConnectionComplete{}}, %{conn: conn} = state) do
    Logger.info("GoveeLEDStrip connection established")
    {:noreply, %{state | connected?: true}}
  end

  # Sent if a connection is dropped
  def handle_info({BlueHeron.ATT.Client, _, %DisconnectionComplete{reason_name: reason}}, state) do
    Logger.warning("GoveeLEDStrip connection dropped: #{reason}")
    {:noreply, %{state | connected?: false}}
  end

  # Ignore other ATT data
  def handle_info({BlueHeron.ATT.Client, _, _event}, state) do
    {:noreply, state}
  end

  @impl GenServer
  # Assembles the raw RGB data into a binary that the bulb expects
  # this was found here https://github.com/Freemanium/govee_btled#analyzing-the-traffic
  def handle_call({:set_color, _rgb}, _from, %{connected?: false} = state) do
    Logger.warning("Not currently connected to a bulb")
    {:reply, {:error, :disconnected}, state}
  end

  def handle_call({:set_color, rgb}, _from, state) do
    # color
    payload =
      <<0x33, 0x5, 0xB, rgb::24, 0xFF, 0x7F, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0, 0x0,
        0x0>>

    checksum = calculate_xor(payload, 0)

    case BlueHeron.ATT.Client.write(state.conn, 0x0015, <<payload::binary-19, checksum::8>>) do
      :ok ->
        Logger.info("Setting GoveeLEDStrip Color: ##{inspect(rgb, base: :hex)}")
        {:reply, :ok, state}

      error ->
        Logger.info("Failed to set GoveeLEDStrip color")
        {:reply, error, state}
    end
  end

  defp calculate_xor(<<>>, checksum), do: checksum

  defp calculate_xor(<<x::8, rest::binary>>, checksum),
    do: calculate_xor(rest, :erlang.bxor(checksum, x))
end
