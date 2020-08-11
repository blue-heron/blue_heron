defmodule Bluetooth.Example.LEScan do
  @moduledoc """
  Example showing how to use BTLE Scan
  """
  use GenServer
  require Logger

  @config %Bluetooth.HCI.Transport.NULL{}

  # Packet Types
  alias Harald.HCI.Event.{LEMeta, LEMeta.AdvertisingReport}
  alias Harald.HCI.LEController

  @doc "Example Entry Point"
  def start_link(config \\ @config) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
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
  # Sent when HCI is up and running
  def handle_info({:BLUETOOTH_EVENT_STATE, :HCI_STATE_WORKING}, state) do
    Bluetooth.hci_command(state.ctx, LEController.set_enable_scan(true))
    {:noreply, state}
  end

  def handle_info({:HCI_EVENT_PACKET, packet}, state) do
    state = handle_hci_packet(packet, state)
    {:noreply, state}
  end

  defp handle_hci_packet(%LEMeta{subevent: %AdvertisingReport{devices: devices}}, state) do
    Enum.reduce(devices, state, fn device, state ->
      put_device(device.address, device, state)
    end)
  end

  defp handle_hci_packet(_, state), do: state

  defp put_device(address, device_report, %{devices: devices} = state) do
    Logger.info """
    New Device Report:
    #{inspect(device_report, base: :hex, limit: :infinity, pretty: true)}
    """
    %{state | devices: Map.put(devices, address, device_report)}
  end
end
