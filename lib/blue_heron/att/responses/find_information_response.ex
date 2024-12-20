defmodule BlueHeron.ATT.FindInformationResponse do
  @moduledoc """
  > The ATT_FIND_INFORMATION_RSP PDU is sent in reply to a received
  > ATT_FIND_INFORMATION_REQ PDU and contains information about this server.

  Bluetooth Spec v5.2, vol 3, Part F, 3.4.3.2
  """

  defstruct [:opcode, :format, :information_data]

  defmodule InformationData do
    @moduledoc """
    Strucutured InformationData encoder/decoder.
    """

    defstruct [:handle, :uuid]

    def serialize(%{handle: handle, uuid: uuid}) when uuid > 65535 do
      <<handle::little-16, uuid::little-128>>
    end

    def serialize(%{handle: handle, uuid: uuid}) do
      <<handle::little-16, uuid::little-16>>
    end

    def deserialize(<<handle::little-16, uuid::little-128>>) do
      %__MODULE__{handle: handle, uuid: uuid}
    end

    def deserialize(<<handle::little-16, uuid::little-16>>) do
      %__MODULE__{handle: handle, uuid: uuid}
    end
  end

  def serialize(%{format: format, information_data: information_data}) do
    information_data =
      for data <- information_data, into: <<>> do
        InformationData.serialize(data)
      end

    <<0x05, format, information_data::binary>>
  end

  def deserialize(<<0x05, format, information_data::binary>>) do
    pair_size =
      case format do
        # 0x01 means pairs of 2 byte UUIDs
        0x01 -> 4
        # 0x02 means pairs of 16 byte UUIDs
        0x02 -> 18
      end

    information_data = chunk_information_data(pair_size, information_data)

    %__MODULE__{
      opcode: 0x05,
      format: format,
      information_data: information_data
    }
  end

  defp chunk_information_data(size, data, acc \\ [])

  defp chunk_information_data(_size, <<>>, acc) do
    Enum.reverse(acc)
  end

  defp chunk_information_data(pair_size, data, acc) do
    <<chunk::binary-size(pair_size), rest::binary>> = data
    acc = [InformationData.deserialize(chunk) | acc]
    chunk_information_data(pair_size, rest, acc)
  end
end
