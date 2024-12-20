defmodule BlueHeron.HCI.Command.LEController.SetScanParameters do
  use BlueHeron.HCI.Command.LEController, ocf: 0x000B

  @moduledoc """
  > The HCI_LE_Set_Scan_Parameters command is used to set the scan parameters.

  Bluetooth Core Version 5.2 | Vol 4, Part E, section 7.8.10

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`
  """

  defparameters le_scan_type: 0x00,
                le_scan_interval: 0x0010,
                le_scan_window: 0x0010,
                own_address_type: 0x00,
                scanning_filter_policy: 0x00

  defimpl BlueHeron.HCI.Serializable do
    def serialize(%{
          opcode: opcode,
          le_scan_type: le_scan_type,
          le_scan_interval: le_scan_interval,
          le_scan_window: le_scan_window,
          own_address_type: own_address_type,
          scanning_filter_policy: scanning_filter_policy
        }) do
      <<opcode::binary, 0x07, le_scan_type, le_scan_interval::little-16,
        le_scan_window::little-16, own_address_type, scanning_filter_policy>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(
        <<@opcode, 0x07, le_scan_type, le_scan_interval::little-16, le_scan_window::little-16,
          own_address_type, scanning_filter_policy>>
      ) do
    new(
      le_scan_type: le_scan_type,
      le_scan_interval: le_scan_interval,
      le_scan_window: le_scan_window,
      own_address_type: own_address_type,
      scanning_filter_policy: scanning_filter_policy
    )
  end

  @impl BlueHeron.HCI.Command
  def deserialize_return_parameters(<<status>>) do
    %{status: status}
  end

  @impl BlueHeron.HCI.Command
  def serialize_return_parameters(%{status: status}) do
    <<BlueHeron.ErrorCode.to_code!(status)>>
  end
end
