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
      %ControllerAndBaseband.Reset{},
      # %InformationalParameters.ReadLocalVersion{},
      %ControllerAndBaseband.ReadLocalName{},
      # %InformationalParameters.ReadLocalSupportedCommands{},
      # %InformationalParameters.ReadBdAddr{},
      # %InformationalParameters.ReadBufferSize{},
      # %InformationalParameters.ReadLocalSupportedFeatures{},
      %ControllerAndBaseband.SetEventMask{enhanced_flush_complete: false},
      %ControllerAndBaseband.WriteSimplePairingMode{enabled: true},
      %ControllerAndBaseband.WritePageTimeout{timeout: 0x60},
      # %LinkPolicy.WriteDefaultLinkPolicySettings{settings: 0x00},
      %ControllerAndBaseband.WriteClassOfDevice{class: 0x0C027A},
      %ControllerAndBaseband.WriteLocalName{name: "Bluetooth Test"},
      # %ControllerAndBaseband.WriteExtendedInquiryResponse(
      #   false,
      #   <<0x1A, 0x9, 0x42, 0x54, 0x73, 0x74, 0x61, 0x63, 0x6B, 0x20, 0x45, 0x20, 0x38, 0x3A, 0x34,
      #     0x45, 0x3A, 0x30, 0x36, 0x3A, 0x38, 0x31, 0x3A, 0x41, 0x34, 0x3A, 0x35, 0x30, 0x20>>
      # ),
      # %ControllerAndBaseband.WriteInquiryMode{mode: 0x0},
      # %ControllerAndBaseband.WriteSecureConnectionsHostSupport{support: true},
      # <<0x1A, 0x0C, 0x01, 0x00>>,
      # <<0x2F, 0x0C, 0x01, 0x01>>,
      # <<0x5B, 0x0C, 0x01, 0x01>>,
      # <<0x02, 0x20, 0x00>>,
      # <<0x6D, 0x0C, 0x02, 0x01, 0x00>>,
      # <<0x0F, 0x20, 0x00>>,
      # <<0x0B, 0x20, 0x07, 0x01, 0x30, 0x00, 0x30, 0x00, 0x00, 0x00>>
    ]
  }

  # Packet Types
  alias Bluetooth.HCI.Event.{LEMeta, LEMeta.AdvertisingReport}
  alias Bluetooth.HCI.LEController

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
    # Bluetooth.hci_command(state.ctx, LEController.set_enable_scan(true))
    {:noreply, state}
  end

  def handle_info({:HCI_EVENT_PACKET, packet}, state) do
    state = handle_hci_packet(packet, state)
    {:noreply, state}
  end

  # defp handle_hci_packet(%LEMeta{subevent: %AdvertisingReport{devices: devices}}, state) do
  #   Enum.reduce(devices, state, fn device, state ->
  #     put_device(device.address, device, state)
  #   end)
  # end

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
  #   Harald.HCI.LEController.create_connection(0x0060, 0x0030, 0x00, peerBdaddrType, peerBdaddr, 0x00, 0x0006, 0x000c, 0x0000, 0x00c8, 0x0004, 0x0006)
  # end
end
