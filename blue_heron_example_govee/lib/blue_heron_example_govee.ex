defmodule BlueHeronExampleGovee do
  @moduledoc """
  Sample ATT application that can control
  the Govee LED Light Bulb
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

  @usb_config %BlueHeronTransportLibUSB{
    vid: 0x0BDA,
    pid: 0xB82C,
    init_commands: [@write_local_name]
  }

  @uart_config %BlueHeronTransportUART{
    device: "ttyACM0",
    uart_opts: [speed: 115_200],
    init_commands: [@write_local_name]
  }

  @doc """
  Start a linked connection to the bulb

  ## UART

      iex> {:ok, pid} = GoveeBTLed.start_link(:uart, device: "ttyACM0")
      {:ok, #PID<0.111.0>}

  ## USB

      iex> {:ok, pid} = GoveeBTLed.start_link(:usb)
      {:ok, #PID<0.111.0>}
  """
  def start_link(transport_type, config \\ %{})

  def start_link(:uart, config) do
    GenServer.start_link(__MODULE__, struct(@uart_config, config), [])
  end

  def start_link(:usb, config) do
    GenServer.start_link(__MODULE__, struct(@usb_config, config), [])
  end

  @doc """
  Set the color of the bulb.

      iex> GoveeBTLed.set_color(pid, 0xFFFFFF) # full white
      :ok
      iex> GoveeBTLed.set_color(pid, 0xFF0000) # full red
      :ok
      iex> GoveeBTLed.set_color(pid, 0x00FF00) # full green
      :ok
      iex> GoveeBTLed.set_color(pid, 0x0000FF) # full blue
      :ok
  """
  def set_color(pid, rgb) do
    GenServer.call(pid, {:set_color, rgb})
  end

  @impl GenServer
  def init(config) do
    # Create a context foro Bluetooth to operate with
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
    BlueHeron.hci_command(state.ctx, %SetScanEnable{le_scan_enable: true})
    {:noreply, state}
  end

  # Match for the Bulb.
  def handle_info(
        {:HCI_EVENT_PACKET,
         %AdvertisingReport{devices: [%Device{address: addr, data: ["\tMinger" <> _]}]}},
        state
      ) do
    Logger.info("Trying to connect to Govee LED #{inspect(addr, base: :hex)}")
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
    Logger.info("Govee LED connection established")
    {:noreply, %{state | connected?: true}}
  end

  # Sent if a connection is dropped
  def handle_info({BlueHeron.ATT.Client, _, %DisconnectionComplete{reason_name: reason}}, state) do
    Logger.warn("Govee LED connection dropped: #{reason}")
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
    Logger.warn("Not currently connected to a bulb")
    {:reply, {:error, :disconnected}, state}
  end

  def handle_call({:set_color, rgb}, _from, state) do
    value = <<0x33, 0x5, 0x2, rgb::24, 0, rgb::24, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
    checksum = calculate_xor(value, 0)

    case BlueHeron.ATT.Client.write(state.conn, 0x0015, <<value::binary-19, checksum::8>>) do
      :ok ->
        Logger.info("Setting Govee LED Color: ##{inspect(rgb, base: :hex)}")
        {:reply, :ok, state}

      error ->
        Logger.info("Failed to set Govee LED color")
        {:reply, error, state}
    end
  end

  defp calculate_xor(<<>>, checksum), do: checksum

  defp calculate_xor(<<x::8, rest::binary>>, checksum),
    do: calculate_xor(rest, :erlang.bxor(checksum, x))
end
