# SPDX-FileCopyrightText: 2020 Connor Rigby
# SPDX-FileCopyrightText: 2020 Frank Hunleth
# SPDX-FileCopyrightText: 2023 Markus Hutzler
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.ATT.ReadByTypeResponse do
  @moduledoc """
  > The ATT_READ_BY_TYPE_RSP PDU is sent in reply to a received
  > ATT_READ_BY_TYPE_REQ PDU and contains the handles and values of the attributes
  > that have been read.

  Bluetooth Spec v5.2, vol 3, Part F, 3.4.4.2
  """

  defmodule AttributeData do
    @moduledoc """
    Structure containing decoders and encoders for the Attribute Data
    """

    defstruct [:handle, :characteristic_properties, :characteristic_value_handle, :value, :uuid]

    def deserialize(<<handle::little-16, properties, value_handle::little-16, uuid::little-16>>) do
      %__MODULE__{
        handle: handle,
        characteristic_properties: properties,
        characteristic_value_handle: value_handle,
        uuid: uuid
      }
    end

    def deserialize(<<handle::little-16, properties, value_handle::little-16, uuid::little-128>>) do
      %__MODULE__{
        handle: handle,
        characteristic_properties: properties,
        characteristic_value_handle: value_handle,
        uuid: uuid
      }
    end

    def serialize(%{
          handle: handle,
          characteristic_properties: characteristic_properties,
          characteristic_value_handle: characteristic_value_handle,
          uuid: uuid,
          value: nil
        })
        when uuid < 0xFFFF do
      <<handle::little-16, characteristic_properties, characteristic_value_handle::little-16,
        uuid::little-16>>
    end

    def serialize(%{
          handle: handle,
          characteristic_properties: characteristic_properties,
          characteristic_value_handle: characteristic_value_handle,
          uuid: uuid,
          value: nil
        })
        when uuid > 0xFFFF do
      <<handle::little-16, characteristic_properties, characteristic_value_handle::little-16,
        uuid::little-128>>
    end

    def serialize(%{
          handle: handle,
          characteristic_properties: _characteristic_properties,
          characteristic_value_handle: _characteristic_value_handle,
          uuid: _uuid,
          value: value
        }) do
      <<handle::little-16, value::binary>>
    end
  end

  defstruct [:opcode, :attribute_data]

  def serialize(%{attribute_data: attribute_data}) do
    [single | _] = attribute_data = for attr <- attribute_data, do: AttributeData.serialize(attr)
    length = byte_size(single)
    <<0x9, length>> <> Enum.join(attribute_data)
  end

  def deserialize(<<0x9, attribute_data_length, attribute_data::binary>>) do
    %__MODULE__{
      opcode: 0x9,
      attribute_data: deserialize_attribute_data(attribute_data_length, attribute_data, [])
    }
  end

  defp deserialize_attribute_data(_, <<>>, acc), do: Enum.reverse(acc)

  defp deserialize_attribute_data(item_length, attribute_data, acc) do
    <<attribute_data::binary-size(item_length), rest::binary>> = attribute_data
    attribute_data = AttributeData.deserialize(attribute_data)
    deserialize_attribute_data(item_length, rest, [attribute_data | acc])
  end
end
