defmodule Bluetooth.HCI.Event.LEMeta.AdvertisingReport do
  use Bluetooth.HCI.Event.LEMeta, subevent_code: 0x02

  @moduledoc """
  A struct representing a LE Advertising Report.

  > The LE Advertising Report event indicates that one or more Bluetooth devices have responded to
  > an active scan or have broadcast advertisements that were received during a passive scan. The
  > Controller may queue these advertising reports and send information from multiple devices in
  > one LE Advertising Report event.
  >
  > This event shall only be generated if scanning was enabled using the LE Set Scan Enable
  > command. It only reports advertising events that used legacy advertising PDUs.

  Reference: Version 5.2, Vol 4, Part E, 7.7.65.2
  """

  alias Bluetooth.HCI.{Event.LEMeta.AdvertisingReport.Device}

  defparameters devices: [], num_reports: 0

  defimpl Bluetooth.HCI.Serializable do
    def serialize(report) do
      {:ok, bin} = Device.serialize(report.devices)
      size = byte_size(bin) + 1

      <<report.code, size, report.subevent_code, bin::binary>>
    end
  end

  @impl Bluetooth.HCI.Event
  def deserialize(<<@code, _size, @subevent_code, arrayed_bin::binary>>) do
    {_, devices} = Device.deserialize(arrayed_bin)
    <<num_reports, _rest::binary>> = arrayed_bin

    %__MODULE__{devices: devices, num_reports: num_reports}
  end

  def deserialize(bin), do: {:error, bin}
end
