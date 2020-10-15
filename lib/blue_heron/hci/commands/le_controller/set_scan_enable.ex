defmodule BlueHeron.HCI.Command.LEController.SetScanEnable do
  use BlueHeron.HCI.Command.LEController, ocf: 0x000C

  defparameters le_scan_enable: false,
                filter_duplicates: false

  defimpl BlueHeron.HCI.Serializable do
    def serialize(cc) do
      fields = <<
        as_uint8(cc.le_scan_enable),
        as_uint8(cc.filter_duplicates)
      >>

      fields_size = byte_size(fields)

      <<cc.opcode::binary, fields_size, fields::binary>>
    end

    defp as_uint8(true), do: 1
    defp as_uint8(false), do: 0
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<@opcode::binary, _fields_size, le_scan_enable, filter_duplicates>>) do
    {:ok,
     %__MODULE__{
       le_scan_enable: as_boolean(le_scan_enable),
       filter_duplicates: as_boolean(filter_duplicates)
     }}
  end

  @impl BlueHeron.HCI.Command
  def deserialize_return_parameters(<<status>>) do
    %{status: status}
  end

  @impl BlueHeron.HCI.Command
  def serialize_return_parameters(%{status: status}) do
    <<BlueHeron.ErrorCode.to_code!(status)>>
  end

  defp as_boolean(val) when val in [1, "1", true, <<1>>], do: true
  defp as_boolean(_), do: false
end
