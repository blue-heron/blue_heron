defmodule BlueHeron.HCI.Event.LEMeta.AdvertisingReport do
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

  # TODO(Connor) - Rewrite this. ArrayedData is broken
  @behaviour BlueHeron.HCI.Event
  alias BlueHeron.HCI.{Event.LEMeta.AdvertisingReport.Device}

  defstruct devices: [], num_reports: 0

  @impl BlueHeron.HCI.Event
  def deserialize(<<num_reports, _::binary>> = arrayed_bin) do
    {_, devices} = Device.deserialize(arrayed_bin)
    # devices
    %__MODULE__{devices: devices, num_reports: num_reports}
  end

  @impl BlueHeron.HCI.Event
  def serialize(%__MODULE__{devices: devices}) do
    {:ok, bin} = Device.serialize(devices)
    bin
  end
end
