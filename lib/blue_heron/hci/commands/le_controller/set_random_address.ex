defmodule BlueHeron.HCI.Command.LEController.SetRandomAddress do
  use BlueHeron.HCI.Command.LEController, ocf: 0x0005

  defparameters random_address: nil

  defimpl BlueHeron.HCI.Serializable do
    def serialize(command) do
      <<command.opcode::binary, 0x06, command.random_address::little-48>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<@opcode::binary, _fields_size, random_address::little-48>>) do
    new(random_address: random_address)
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
