defmodule Bluetooth.ATT do
  # this is missing the flags. Opcodes will be wrong. Sorry.
  defstruct [:opcode, :args]

  defmodule ErrorResponse do
    defstruct [:opcode, :request_opcode, :handle, :error]

    def serialize(%{request_opcode: request_opcode, handle: handle, error: error}) do
      <<0x01::8, request_opcode::8, handle::little-16, serialize_error(error)::8>>
    end

    defp serialize_error(:attribute_not_found), do: 0x0A

    def deserialize(<<0x01::8, request_opcode::8, handle::little-16, error::8>>) do
      %__MODULE__{
        opcode: 0x01,
        request_opcode: request_opcode,
        handle: handle,
        error: deserialize_error(error)
      }
    end

    defp deserialize_error(0x0A), do: :attribute_not_found
    defp deserialize_error(code), do: code
  end

  defmodule ExchageMTURequest do
    defstruct [:opcode, :client_rx_mtu]

    def serialize(emtu) do
      <<0x02::8, emtu.client_rx_mtu::little-16>>
    end

    def deserialize(<<0x02::8, client_rx_mtu::little-16>>) do
      %__MODULE__{opcode: 0x02, client_rx_mtu: client_rx_mtu}
    end
  end

  defmodule ExchageMTUResponse do
    defstruct [:opcode, :server_rx_mtu]

    def serialize(emtu) do
      <<0x03::8, emtu.server_rx_mtu::little-16>>
    end

    def deserialize(<<0x03::8, server_rx_mtu::little-16>>) do
      %__MODULE__{opcode: 0x03, server_rx_mtu: server_rx_mtu}
    end
  end

  defmodule ReadByTypeRequest do
    defstruct [:opcode, :starting_handle, :ending_handle, :uuid]

    def serialize(%{
          starting_handle: starting_handle,
          ending_handle: ending_handle,
          uuid: uuid
        })
        when uuid > 65535 do
      <<0x8::8, starting_handle::little-16, ending_handle::little-16, uuid::little-128>>
    end

    def serialize(%{
          starting_handle: starting_handle,
          ending_handle: ending_handle,
          uuid: uuid
        }) do
      <<0x8::8, starting_handle::little-16, ending_handle::little-16, uuid::little-16>>
    end

    def deserialize(
          <<0x8::8, starting_handle::little-16, ending_handle::little-16, uuid::little-16>>
        ) do
      %__MODULE__{
        opcode: 0x8,
        starting_handle: starting_handle,
        ending_handle: ending_handle,
        uuid: uuid
      }
    end

    def deserialize(
          <<0x8::8, starting_handle::little-16, ending_handle::little-16, uuid::little-128>>
        ) do
      %__MODULE__{
        opcode: 0x8,
        starting_handle: starting_handle,
        ending_handle: ending_handle,
        uuid: uuid
      }
    end
  end

  defmodule ReadByTypeResponse do
    defmodule AttributeDate do
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
    def serialize(_), do: raise("connor forgot to implement this")

    def deserialize(<<0x9, attribute_data_length::8, attribute_data::binary>>) do
      %__MODULE__{
        opcode: 0x9,
        attribute_data: deserialize_attribute_data(attribute_data_length, attribute_data, [])
      }
    end

    defp deserialize_attribute_data(_, <<>>, acc), do: Enum.reverse(acc)

    defp deserialize_attribute_data(item_length, attribute_data, acc) do
      <<attribute_data::binary-size(item_length), rest::binary>> = attribute_data
      attribute_data = AttributeDate.deserialize(attribute_data)
      deserialize_attribute_data(item_length, rest, [attribute_data | acc])
    end
  end

  defmodule ReadByGroupTypeRequest do
    defstruct [:opcode, :starting_handle, :ending_handle, :uuid]

    def serialize(%{
          starting_handle: starting_handle,
          ending_handle: ending_handle,
          uuid: uuid
        })
        when uuid > 65535 do
      <<0x10::8, starting_handle::little-16, ending_handle::little-16, uuid::little-128>>
    end

    def serialize(%{
          starting_handle: starting_handle,
          ending_handle: ending_handle,
          uuid: uuid
        }) do
      <<0x10::8, starting_handle::little-16, ending_handle::little-16, uuid::little-16>>
    end

    def deserialize(
          <<0x10::8, starting_handle::little-16, ending_handle::little-16, uuid::little-16>>
        ) do
      %__MODULE__{
        opcode: 0x10,
        starting_handle: starting_handle,
        ending_handle: ending_handle,
        uuid: uuid
      }
    end

    def deserialize(
          <<0x10::8, starting_handle::little-16, ending_handle::little-16, uuid::little-128>>
        ) do
      %__MODULE__{
        opcode: 0x10,
        starting_handle: starting_handle,
        ending_handle: ending_handle,
        uuid: uuid
      }
    end
  end

  defmodule ReadByGroupTypeResponse do
    defstruct [:opcode, :attribute_data]

    defmodule AttributeData do
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

    def deserialize(<<0x11, length::8, attribute_data::binary>>) do
      %__MODULE__{
        opcode: 0x11,
        attribute_data: deserialize_attribute_data(length, attribute_data, [])
      }
    end

    defp deserialize_attribute_data(_, <<>>, attribute_data), do: Enum.reverse(attribute_data)

    defp deserialize_attribute_data(item_length, data, acc) do
      <<attribute_data::binary-size(item_length), rest::binary>> = data
      attribute_data = AttributeData.deserialize(attribute_data)
      deserialize_attribute_data(item_length, rest, [attribute_data | acc])
    end
  end

  defmodule HandleValueNTF do
    defstruct [:opcode, :handle, :data]

    def deserialize(<<0x1B, handle::little-16, data::binary>>) do
      %__MODULE__{opcode: 0x1B, handle: handle, data: data}
    end

    def serialize(%{data: %type{} = data} = write_command) do
      serialize(%{write_command | data: type.serialize(data)})
    end

    def serialize(%{handle: handle, data: data}) do
      <<0x1B::8, handle::little-16, data::binary>>
    end
  end

  defmodule WriteCommand do
    defstruct [:opcode, :handle, :data]

    def deserialize(<<0x52, handle::little-16, data::binary>>) do
      %__MODULE__{opcode: 0x52, handle: handle, data: data}
    end

    def serialize(%{data: %type{} = data} = write_command) do
      serialize(%{write_command | data: type.serialize(data)})
    end

    def serialize(%{handle: handle, data: data}) do
      <<0x52::8, handle::little-16, data::binary>>
    end
  end

  def deserialize(base, <<0x01::8, _::binary>> = error_response),
    do: %{base | data: ErrorResponse.deserialize(error_response)}

  def deserialize(base, <<0x02::8, _::binary>> = exchange_mtu_request),
    do: %{base | data: ExchageMTURequest.deserialize(exchange_mtu_request)}

  def deserialize(base, <<0x03::8, _::binary>> = exchange_mtu_request),
    do: %{base | data: ExchageMTUResponse.deserialize(exchange_mtu_request)}

  def deserialize(base, <<0x08::8, _::binary>> = exchange_mtu_request),
    do: %{base | data: ReadByTypeRequest.deserialize(exchange_mtu_request)}

  def deserialize(base, <<0x09::8, _::binary>> = exchange_mtu_request),
    do: %{base | data: ReadByTypeResponse.deserialize(exchange_mtu_request)}

  def deserialize(base, <<0x10::8, _::binary>> = read_by_group_type_request),
    do: %{base | data: ReadByGroupTypeRequest.deserialize(read_by_group_type_request)}

  def deserialize(base, <<0x11::8, _::binary>> = read_by_group_type_request),
    do: %{base | data: ReadByGroupTypeResponse.deserialize(read_by_group_type_request)}

  def deserialize(base, <<0x1B::8, _::binary>> = read_by_group_type_request),
    do: %{base | data: HandleValueNTF.deserialize(read_by_group_type_request)}

  def deserialize(base, <<0x52::8, _::binary>> = read_by_group_type_request),
    do: %{base | data: WriteCommand.deserialize(read_by_group_type_request)}

  def deserialize(base, <<opcode::8, args::binary>>),
    do: %{base | data: %__MODULE__{opcode: opcode, args: args}}

  def serialize(%__MODULE__{opcode: opcode, args: args}) do
    <<opcode::8, args::binary>>
  end

  def serialize(%type{} = data), do: type.serialize(data)
end
