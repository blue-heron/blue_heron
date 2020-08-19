defmodule Bluetooth.Example.LEScanConnect do
  @moduledoc """
  Example showing how to use BTLE Scan
  """
  use GenServer
  require Logger

  alias Bluetooth.HCI.Command.{
    ControllerAndBaseband,
    InformationalParameters,
    LinkPolicy
  }

  @config %Bluetooth.HCI.Transport.LibUSB{
    vid: 0x0BDA,
    pid: 0xB82C,
    init_commands: [
      %ControllerAndBaseband.WriteLocalName{name: "BLE Scan Test"},
    ]
  }

  # Packet Types
  alias Bluetooth.HCI.Event.LEMeta.AdvertisingReport
  alias Bluetooth.HCI.Command.LEController.SetScanEnable

  @doc "Example Entry Point"
  def start_link(config \\ @config) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  def devices() do
    GenServer.call(__MODULE__, :devices)
  end

  @impl GenServer
  def init(config) do
    # Initialize everything
    {:ok, ctx} = Bluetooth.transport(config)
    :ok = Bluetooth.add_event_handler(ctx)

    state = %{
      ctx: ctx,
      config: config,
      devices: %{}
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_call(:devices, _from, state), do: {:reply, state.devices, state}

  @impl GenServer
  # Sent when HCI is up and running
  def handle_info({:BLUETOOTH_EVENT_STATE, :HCI_STATE_WORKING}, state) do
    Bluetooth.hci_command(state.ctx, %SetScanEnable{le_scan_enable: true})
    {:noreply, state}
  end

  def handle_info({:HCI_EVENT_PACKET, packet}, state) do
    state = handle_hci_packet(packet, state)
    {:noreply, state}
  end

  defp handle_hci_packet(%AdvertisingReport{devices: devices}, state) do
    Enum.reduce(devices, state, fn device, state ->
      put_device(device.address, device, state)
    end)
  end

  defp handle_hci_packet(hci, state) do
    IO.inspect(hci, label: "UNHANDLED HCI COMMAND", base: :hex, limit: :infinity)
    state
  end

  defp put_device(address, device_report, %{devices: devices} = state) do
    unless state.devices[address] do
      Logger.info("""
      New Device Report:
      #{inspect(device_report, base: :hex, limit: :infinity, pretty: true)}
      """)
    end

    %{state | devices: Map.put(devices, address, device_report)}
  end

  # def connect(peerBdaddrType, peerBdaddr) do
  #   Harald.HCI..create_connection(0x0060, 0x0030, 0x00, peerBdaddrType, peerBdaddr, 0x00, 0x0006, 0x000c, 0x0000, 0x00c8, 0x0004, 0x0006)
  # end
end
