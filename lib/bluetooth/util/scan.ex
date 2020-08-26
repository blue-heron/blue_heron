defmodule Bluetooth.Util.Scan do
  def scan_print(ctx) do
    spawn(fn ->
      Bluetooth.add_event_handler(ctx)

      receive do
        {:BLUETOOTH_EVENT_STATE, :HCI_STATE_WORKING} ->
          Bluetooth.hci_command(ctx, %Bluetooth.HCI.Command.LEController.SetScanEnable{
            le_scan_enable: true
          })
      after
        1000 ->
          raise "Timeout"
      end

      _scan_print(ctx, %{})
    end)

    ctx
  end

  defp _scan_print(ctx, devices) do
    receive do
      {:HCI_EVENT_PACKET,
       %Bluetooth.HCI.Event.LEMeta.AdvertisingReport{
         devices: new_devices
       }} ->
        devices =
          Enum.reduce(new_devices, devices, fn device, devices ->
            unless devices[device.address] do
              IO.inspect(device)
            end

            put_device(device.address, device, devices)
          end)

        _scan_print(ctx, devices)
    end
  end

  defp put_device(address, device_report, devices) do
    Map.put(devices, address, device_report)
  end

  def scan(ctx) do
    Bluetooth.add_event_handler(ctx)

    receive do
      {:BLUETOOTH_EVENT_STATE, :HCI_STATE_WORKING} ->
        Bluetooth.hci_command(ctx, %Bluetooth.HCI.Command.LEController.SetScanEnable{
          le_scan_enable: true
        })
    after
      1000 ->
        raise "Timeout"
    end

    ctx
  end

  def scan_for_led_bulb(ctx) do
    ctx = scan(ctx)

    receive do
      {:HCI_EVENT_PACKET,
       %Bluetooth.HCI.Event.LEMeta.AdvertisingReport{
         devices: [
           %Bluetooth.HCI.Event.LEMeta.AdvertisingReport.Device{
             address: addr,
             data: ["\tMinger" <> _]
           }
         ]
       }} ->
        IO.inspect(addr, base: :hex, label: "LED BULB ADDR")
    end

    ctx
  end
end
