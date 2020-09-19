defmodule BlueHeron.HCI.Helpers do
  alias BlueHeron.HCI

  @doc """
  Helper to create Command opcode from OCF and OGF values
  """
  @spec op(HCI.ogf(), HCI.ocf()) :: HCI.opcode()
  defmacro op(ogf, ocf) do
    ogf = Macro.expand(ogf, __CALLER__)
    ocf = Macro.expand(ocf, __CALLER__)
    <<opcode::16>> = <<ogf::6, ocf::10>>
    opcode

    # ogf * 1024 + ocf
  end

  @moduledoc false
  @spec boolean_to_uint8(any()) :: 0 | 1
  def boolean_to_uint8(val) when val in [1, "1", true, <<1>>], do: 1
  def boolean_to_uint8(_val), do: 0

  @doc """
  Trim everything past the first null byte in a binary
  """
  @spec trim_zero(binary()) :: binary()
  def trim_zero(data) do
    [return_data | _ignore] = :binary.split(data, <<0>>)
    return_data
  end
end
