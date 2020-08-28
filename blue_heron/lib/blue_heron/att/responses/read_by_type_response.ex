defmodule BlueHeron.ATT.ReadByTypeResponse do
  defmodule AttributeData do
    defstruct [:handle, :characteristic_properties, :characteristic_value_handle, :uuid]

    def deserialize(
          <<handle::little-16, properties::8, value_handle::little-16, uuid::little-16>>
        ) do
      %__MODULE__{
        handle: handle,
        characteristic_properties: properties,
        characteristic_value_handle: value_handle,
        uuid: uuid
      }
    end

    def deserialize(
          <<handle::little-16, properties::8, value_handle::little-16, uuid::little-128>>
        ) do
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
          uuid: uuid
        })
        when uuid < 0xFFFF do
      <<handle::little-16, characteristic_properties::8, characteristic_value_handle::little-16,
        uuid::little-16>>
    end

    def serialize(%{
          handle: handle,
          characteristic_properties: characteristic_properties,
          characteristic_value_handle: characteristic_value_handle,
          uuid: uuid
        })
        when uuid > 0xFFFF do
      <<handle::little-16, characteristic_properties::8, characteristic_value_handle::little-16,
        uuid::little-128>>
    end
  end

  defstruct [:opcode, :attribute_data]

  def serialize(%{attribute_data: attribute_data}) do
    [single | _] = attribute_data = for attr <- attribute_data, do: AttributeData.serialize(attr)
    length = byte_size(single)
    <<0x9, length::8>> <> Enum.join(attribute_data)
  end

  def deserialize(<<0x9, attribute_data_length::8, attribute_data::binary>>) do
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
