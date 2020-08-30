defmodule BlueHeron.HCI.Command.LEController.SetScanEnable do
  @moduledoc """
  The HCI_LE_Set_Scan_Enable command is used to start and stop scanning.
  Scanning is used to discover advertising devices nearby.

  Bluetooth Core Version 5.2 | Vol 4, Part E, section 7.8.11

  * OGF: `0x0C`
  * OCF: `0x8`
  * Opcode: `0x200C`
  """

  @behaviour BlueHeron.HCI.Command
  defstruct le_scan_enable: false,
            filter_duplicates: false

  @impl BlueHeron.HCI.Command
  def opcode(), do: 0x200C

  @impl BlueHeron.HCI.Command
  def serialize(cc) do
    <<
      as_uint8(cc.le_scan_enable),
      as_uint8(cc.filter_duplicates)
    >>
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<le_scan_enable::8, filter_duplicates::8>>) do
    %__MODULE__{
      le_scan_enable: as_boolean(le_scan_enable),
      filter_duplicates: as_boolean(filter_duplicates)
    }
  end

  @impl BlueHeron.HCI.Command
  def deserialize_return_parameters(<<status::8>>) do
    %{status: status, status_name: BlueHeron.ErrorCode.name!(status)}
  end

  @impl BlueHeron.HCI.Command
  def serialize_return_parameters(%{status: status}) do
    <<status::8>>
  end

  defp as_boolean(val) when val in [1, "1", true, <<1>>], do: true
  defp as_boolean(_), do: false
  defp as_uint8(true), do: 1
  defp as_uint8(false), do: 0
end
