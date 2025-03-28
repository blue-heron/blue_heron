# SPDX-FileCopyrightText: 2020 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Event.LEMeta.AdvertisingReport do
  use BlueHeron.HCI.Event.LEMeta, subevent_code: 0x02

  @moduledoc """
  > The LE Advertising Report event indicates that one or more Bluetooth devices have responded to
  > an active scan or have broadcast advertisements that were received during a passive scan. The
  > Controller may queue these advertising reports and send information from multiple devices in
  > one LE Advertising Report event.

  Reference: Version 5.2, Vol 4, Part E, 7.7.65.2
  """

  alias BlueHeron.HCI.{Event.LEMeta.AdvertisingReport.Device}

  defparameters devices: [], num_reports: 0

  defimpl BlueHeron.HCI.Serializable do
    def serialize(report) do
      {:ok, bin} = Device.serialize(report.devices)
      size = byte_size(bin) + 1

      <<report.code, size, report.subevent_code, bin::binary>>
    end
  end

  @impl BlueHeron.HCI.Event
  def deserialize(<<@code, _size, @subevent_code, arrayed_bin::binary>>) do
    {_, devices} = Device.deserialize(arrayed_bin)
    <<num_reports, _rest::binary>> = arrayed_bin

    %__MODULE__{devices: devices, num_reports: num_reports}
  end

  def deserialize(bin), do: {:error, bin}
end
