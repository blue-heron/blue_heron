defmodule BlueHeron.HCI.Command.LinkControl.Disconnect do
  use BlueHeron.HCI.Command.LinkControl, ocf: 0x0006

  defparameters [reason: 0x16, connection_handle: 0]

  defimpl BlueHeron.HCI.Serializable do
    def serialize(%{opcode: opcode, connection_handle: handle, reason: reason}) do
      bin = <<handle::little-16, reason>>
      size = byte_size(bin)
      <<opcode::binary, size, bin::binary>>
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
  def deserialize_return_parameters(<<>>) do
    %{}
  end

  @impl true
  def serialize_return_parameters(%{}) do
    <<>>
  end
end
