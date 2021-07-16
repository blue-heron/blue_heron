defmodule BlueHeron.HCI.Command.ControllerAndBaseband.WriteScanEnable do
  use BlueHeron.HCI.Command.ControllerAndBaseband, ocf: 0x001A

  @moduledoc """
  This command writes the value for the Scan_Enable configuration parameter.

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`

  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.18

  The Scan_Enable parameter controls whether or not the BR/EDR Controller will
  periodically scan for page attempts and/or inquiry requests from other BR/EDR
  Controllers. If Page Scan is enabled, then the device will enter page scan
  mode based on the value of the Page_Scan_Interval and Page_Scan_Window
  parameters. If Inquiry Scan is enabled, then the BR/EDR Controller will enter
  Inquiry Scan mode based on the value of the Inquiry_Scan_Interval and
  Inquiry_Scan_Window parameters.

  ## Command Parameters
  * `scan_enable`:
    * `0x00` - No scans enabled. **Default**.
    * `0x01` - Inquiry Scan enabled. Page Scan disabled.
    * `0x02` - Inquiry Scan disabled. Page Scan enabled.
    * `0x03` - Inquiry Scan enabled. Page Scan enabled.

  ## Return Parameters
  * `:status` - see `BlueHeron.ErrorCode`
  """

  defparameters scan_enable: 0x00

  defimpl BlueHeron.HCI.Serializable do
    def serialize(%{opcode: opcode, scan_enable: scan_enable}) do
      <<opcode::binary, scan_enable::little-16>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<@opcode::binary, scan_enable::little-16>>) do
    new(scan_enable: scan_enable)
  end

  @impl BlueHeron.HCI.Command
  def deserialize_return_parameters(<<status>>) do
    %{status: status}
  end

  @impl true
  def serialize_return_parameters(%{status: status}) do
    <<BlueHeron.ErrorCode.to_code!(status)>>
  end
end
