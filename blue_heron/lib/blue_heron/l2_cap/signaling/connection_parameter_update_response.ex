defmodule BlueHeron.L2Cap.Signaling.ConnectionParameterUpdateResponse do
  defstruct code: 0x13, identifier: nil, reason: nil

  def deserialize(<<0x13, identifier, length::little-16, reason::binary-size(length)>>) do
    case reason do
      <<0x0000::little-16>> -> %__MODULE__{identifier: identifier, reason: :accepted}
      <<0x0001::little-16>> -> %__MODULE__{identifier: identifier, reason: :rejected}
      <<other::little-16>> -> %__MODULE__{identifier: identifier, reason: other}
    end
  end

  def serialize(%{identifier: identifier, reason: :accepted}) do
    <<0x13, identifier, 2::little-16, 0x0000::little-16>>
  end

  def serialize(%{identifier: identifier, reason: :rejected}) do
    <<0x13, identifier, 2::little-16, 0x0001::little-16>>
  end

  def serialize(%{identifier: identifier, reason: other}) when other <= 0xFF do
    <<0x13, identifier, 2::little-16, other::little-16>>
  end
end
