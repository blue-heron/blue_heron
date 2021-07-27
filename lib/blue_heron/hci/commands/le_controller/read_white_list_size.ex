defmodule BlueHeron.HCI.Command.LEController.ReadWhiteListSize do
  use BlueHeron.HCI.Command.LEController, ocf: 0x000F

  defparameters []

  defimpl BlueHeron.HCI.Serializable do
    def serialize(%{opcode: opcode}) do
      <<opcode::binary, 0x00>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<@opcode::binary, 0x00>>) do
    new()
  end

  @impl BlueHeron.HCI.Command
  def deserialize_return_parameters(<<status, white_list_size>>) do
    %{
      status: status,
      white_list_size: white_list_size
    }
  end

  @impl BlueHeron.HCI.Command
  def serialize_return_parameters(%{status: status, white_list_size: white_list_size}) do
    <<BlueHeron.ErrorCode.to_code!(status), white_list_size>>
  end
end
