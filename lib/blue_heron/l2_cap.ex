# SPDX-FileCopyrightText: 2020 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.L2Cap do
  @moduledoc """
  > Logical Link Control and Adaptation Protocol Specification.

  Bluetooth Spec v5.2, vol 4, Part A
  """
  defstruct [:data, :cid]

  def deserialize(<<length::little-16, cid::little-16, data::binary-size(length)>>) do
    case cid do
      # att
      0x4 ->
        BlueHeron.ATT.deserialize(%__MODULE__{cid: cid}, data)

      _ ->
        %__MODULE__{
          cid: cid,
          data: data
        }
    end
  end

  def serialize(%__MODULE__{data: %type{} = data} = l2cap) do
    serialize(%{l2cap | data: type.serialize(data)})
  end

  def serialize(%__MODULE__{cid: cid, data: data}) do
    length = byte_size(data)
    <<length::little-16, cid::little-16, data::binary-size(length)>>
  end
end
