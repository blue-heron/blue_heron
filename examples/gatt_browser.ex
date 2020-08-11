defmodule Bluetooth.Example.GATTBrowser do
  @moduledoc """
  Example usage of Bluetooth
  """

  use GenServer

  @config %Bluetooth.HCI.Transport.NULL{}

  def start_link(config \\ @config) do
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  @impl GenServer
  def init(config) do
    # Initialize everything
    {:ok, ctx} = Bluetooth.transport(config)
    ctx =
      ctx
      |> Bluetooth.l2cap()
      |> Bluetooth.sm()
      # |> Bluetooth.

    :ok = Bluetooth.add_event_handler(ctx)

    state = %{
      ctx: ctx,
      config: config
    }

    {:ok, state}
  end

  @impl GenServer
  def handle_info({:HCI_EVENT_PACKET, packet}, state) do
    state = handle_hci_packet(packet, state)
    {:noreply, state}
  end

  defp handle_hci_packet(_, state), do: state
end
