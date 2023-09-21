defmodule BlueHeron.HCI.Command.LEController.ReadLocalSupportedFeatures do
  use BlueHeron.HCI.Command.LEController, ocf: 0x0003

  defparameters []

  defimpl BlueHeron.HCI.Serializable do
    def serialize(command) do
      <<command.opcode::binary, 0>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<@opcode::binary, 0>>) do
    new()
  end

  @impl BlueHeron.HCI.Command
  def deserialize_return_parameters(<<status, le_features::little-64>>) do
    %{status: status, le_features: le_features}
  end

  @impl BlueHeron.HCI.Command
  def serialize_return_parameters(%{status: status, le_features: features}) do
    <<BlueHeron.ErrorCode.to_code!(status), features::little-64>>
  end
end
