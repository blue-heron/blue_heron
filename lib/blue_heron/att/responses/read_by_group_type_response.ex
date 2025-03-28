# SPDX-FileCopyrightText: 2020 Connor Rigby
# SPDX-FileCopyrightText: 2020 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.ATT.ReadByGroupTypeResponse do
  @moduledoc """
  > The ATT_READ_BY_GROUP_TYPE_RSP PDU is sent in reply to a received
  > ATT_READ_BY_GROUP_TYPE_REQ PDU and contains the handles and values of the
  > attributes that have been read

  Bluetooth Spec v5.2, vol 3, Part F, 3.4.4.10
  """

  defstruct [:opcode, :attribute_data]

  defmodule AttributeData do
    @moduledoc """
    Strucutured AttributeData encoder/decoder.
    """
    defstruct [:handle, :end_group_handle, :uuid]

    def deserialize(<<handle::little-16, end_group_handle::little-16, uuid::little-16>>) do
      %__MODULE__{handle: handle, end_group_handle: end_group_handle, uuid: uuid}
    end

    def deserialize(<<handle::little-16, end_group_handle::little-16, uuid::little-128>>) do
      %__MODULE__{handle: handle, end_group_handle: end_group_handle, uuid: uuid}
    end

    def serialize(%{handle: handle, end_group_handle: end_group_handle, uuid: uuid})
        when uuid > 65535 do
      <<handle::little-16, end_group_handle::little-16, uuid::little-128>>
    end

    def serialize(%{handle: handle, end_group_handle: end_group_handle, uuid: uuid}) do
      <<handle::little-16, end_group_handle::little-16, uuid::little-16>>
    end
  end

  def deserialize(<<0x11, length, attribute_data::binary>>) do
    %__MODULE__{
      opcode: 0x11,
      attribute_data: deserialize_attribute_data(length, attribute_data, [])
    }
  end

  def serialize(%{attribute_data: attribute_data}) do
    [single | _] = attribute_data = for attr <- attribute_data, do: AttributeData.serialize(attr)
    length = byte_size(single)
    <<0x11, length>> <> Enum.join(attribute_data)
  end

  defp deserialize_attribute_data(_, <<>>, attribute_data), do: Enum.reverse(attribute_data)

  defp deserialize_attribute_data(item_length, data, acc) do
    <<attribute_data::binary-size(item_length), rest::binary>> = data
    attribute_data = AttributeData.deserialize(attribute_data)
    deserialize_attribute_data(item_length, rest, [attribute_data | acc])
  end
end
