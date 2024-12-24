defmodule BlueHeron.HCI.Command.InformationalParameters.ReadBdAddr do
  use BlueHeron.HCI.Command.InformationalParameters, ocf: 0x0009

  @moduledoc """
  > On a BR/EDR Controller, this command reads the Bluetooth Controller address
  > (BD_ADDR).

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`

  Bluetooth Spec v5.3, Vol 4, Part E, section 7.4.6
  """

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
    <<status>> <> BlueHeron.Address.serialize(params.bd_addr)
  end
end
