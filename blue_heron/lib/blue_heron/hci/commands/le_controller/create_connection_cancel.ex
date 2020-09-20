defmodule BlueHeron.HCI.Command.LEController.CreateConnectionCancel do
  use BlueHeron.HCI.Command.LEController, ocf: 0x000E
  defparameters([])

  defimpl BlueHeron.HCI.Serializable do
    def serialize(%{opcode: opcode}) do
      <<opcode::binary, 0>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<@opcode::binary, 0>>) do
    # This is a pretty useless function because there aren't
    # any parameters to actually parse out of this, but we
    # can at least assert its correct with matching
    %__MODULE__{}
  end

  @impl BlueHeron.HCI.Command
  def deserialize_return_parameters(<<status>>) do
    %{status: BlueHeron.ErrorCode.name!(status)}
  end

  @impl true
  def serialize_return_parameters(%{status: status}) do
    <<BlueHeron.ErrorCode.error_code!(status)>>
  end
end
