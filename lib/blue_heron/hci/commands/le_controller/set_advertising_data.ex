defmodule BlueHeron.HCI.Command.LEController.SetAdvertisingData do
  use BlueHeron.HCI.Command.LEController, ocf: 0x0008

  defparameters advertising_data: <<>>

  defimpl BlueHeron.HCI.Serializable do
    def serialize(%{opcode: opcode, advertising_data: advertising_data}) do
      length = byte_size(advertising_data)
      padding_size = (31 - length) * 8

      <<opcode::binary, 32, length, advertising_data::binary, 0::size(padding_size)>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(
        <<@opcode::binary, 32, length, advertising_data::binary-size(length), _rest::binary>>
      ) do
    new(advertising_data: advertising_data)
  end

  @impl BlueHeron.HCI.Command
  def deserialize_return_parameters(<<status>>) do
    %{status: status}
  end

  @impl BlueHeron.HCI.Command
  def serialize_return_parameters(%{status: status}) do
    <<BlueHeron.ErrorCode.to_code!(status)>>
  end
end
