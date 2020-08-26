defmodule Bluetooth.Util do
  alias Bluetooth.HCI.Command.LEController.CreateConnection

  alias Bluetooth.HCI.Event.LEMeta.ConnectionComplete

  def create_connection(addr) do
    ctx = create_ctx(true)

    cmd = %CreateConnection{
      connection_interval_max: 0x0018,
      connection_interval_min: 0x0008,
      connection_latency: 0x0004,
      initiator_filter_policy: 0,
      le_scan_interval: 0x0060,
      le_scan_window: 0x0030,
      max_ce_length: 0x0030,
      min_ce_length: 0x0002,
      own_address_type: 0,
      peer_address: addr,
      peer_address_type: 0,
      supervision_timeout: 0x0048
    }

    {:ok, _} = Bluetooth.hci_command(ctx, cmd)

    receive do
      {:HCI_EVENT_PACKET, %ConnectionComplete{} = connection} -> {ctx, connection}
    after
      1000 ->
        raise "Timeout waiting for connection"
    end
  end

  def scan do
    ctx = create_ctx()
    Bluetooth.Util.Scan.scan(ctx)
  end

  def scan_print do
    ctx = create_ctx()
    Bluetooth.Util.Scan.scan_print(ctx)
  end

  def create_ctx(events? \\ false) do
    {:ok, ctx} = Bluetooth.transport(%Bluetooth.HCI.Transport.LibUSB{})

    if events? do
      Bluetooth.add_event_handler(ctx)
    end

    ctx
  end
end
