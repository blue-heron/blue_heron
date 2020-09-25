defmodule BlueHeron.L2Cap.Signaling.CommandRejectResponse do
  defstruct code: 0x1, identifier: nil, reason: nil

  def deserialize(<<0x1, identifier, length::little-16, reason::binary-size(length)>>) do
    case reason do
      <<0x0000::little-16>> ->
        %__MODULE__{identifier: identifier, reason: :command_not_understood}

      <<0x0001::little-16>> ->
        %__MODULE__{identifier: identifier, reason: :mtu_exceded}

      <<0x0002::little-16>> ->
        %__MODULE__{identifier: identifier, reason: :invalid_cid}

      <<other>> ->
        %__MODULE__{identifier: identifier, reason: other}

      <<>> ->
        %__MODULE__{identifier: identifier, reason: nil}
    end
  end

  def serialize(%{identifier: identifier, reason: :command_not_understood}) do
    <<0x1, identifier, 2::little-16, 0x0000::little-16>>
  end

  def serialize(%{identifier: identifier, reason: :mtu_exceded}) do
    <<0x1, identifier, 2::little-16, 0x0001::little-16>>
  end

  def serialize(%{identifier: identifier, reason: :invalid_cid}) do
    <<0x1, identifier, 2::little-16, 0x0002::little-16>>
  end

  def serialize(%{identifier: identifier, reason: nil}) do
    <<0x1, identifier, 0::little-16>>
  end

  def serialize(%{identifier: identifier, reason: other}) when other <= 0xFF do
    <<0x1, identifier, 2::little-16, other::little-16>>
  end
end
