defmodule BlueHeron.HCI.Command.InformationalParameters.ReadBRADDR do
  use BlueHeron.HCI.Command.InformationalParameters, ocf: 0x0009

  defparameters []

  defimpl BlueHeron.HCI.Serializable do
    def serialize(rlv) do
      <<rlv.opcode::binary, 0>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<@opcode::binary, 0>>) do
    %__MODULE__{}
  end

  @impl BlueHeron.HCI.Command
  def deserialize_return_parameters(<<status, addr::little-unsigned-integer-size(48)>>) do
    %{
      status: status,
      bd_addr: BlueHeron.Address.parse(addr)
    }
  end

  @impl BlueHeron.HCI.Command
  def serialize_return_parameters(%{status: status} = params) do
    <<status>> <> params.bd_addr.binary()
  end
end
