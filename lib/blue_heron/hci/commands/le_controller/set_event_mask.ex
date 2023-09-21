defmodule BlueHeron.HCI.Command.LEController.SetEventMask do
  use BlueHeron.HCI.Command.LEController, ocf: 0x08

  defparameters mask: 0x00

  defimpl BlueHeron.HCI.Serializable do
    def serialize(command) do
      <<command.opcode::binary, 8, command.mask::little-64>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<@opcode::binary, _, mask::little-64>>) do
    new(mask: mask)
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
