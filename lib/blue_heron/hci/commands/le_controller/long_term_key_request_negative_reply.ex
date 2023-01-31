defmodule BlueHeron.HCI.Command.LEController.LongTermKeyRequestNegativeReply do
  use BlueHeron.HCI.Command.LEController, ocf: 0x001B

  defparameters [
    :status,
    :connection_handle
  ]

  defimpl BlueHeron.HCI.Serializable do
    def serialize(%{opcode: opcode, connection_handle: handle}) do
      <<opcode::binary, 2, handle::little-16>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<@opcode::binary, 2, lower_handle, _::4, upper_handle::4>>) do
    <<handle::little-12>> = <<lower_handle, upper_handle::4>>

    %__MODULE__{
      opcode: @opcode,
      connection_handle: handle
    }
  end

  @impl BlueHeron.HCI.Command
  def deserialize_return_parameters(<<status, lower_handle, _::4, upper_handle::4>>) do
    <<handle::little-12>> = <<lower_handle, upper_handle::4>>
    %{status: status, connection_handle: handle}
  end

  @impl BlueHeron.HCI.Command
  def serialize_return_parameters(%{status: status, connection_handle: handle}) do
    <<BlueHeron.ErrorCode.to_code!(status), handle::little-16>>
  end
end
