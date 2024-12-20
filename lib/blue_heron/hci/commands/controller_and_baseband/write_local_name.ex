defmodule BlueHeron.HCI.Command.ControllerAndBaseband.WriteLocalName do
  use BlueHeron.HCI.Command.ControllerAndBaseband, ocf: 0x0013

  @moduledoc """
  > he HCI_Write_Local_Name command provides the ability to modify the user-friendly
  > name for the BR/EDR Controller.

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`

  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.11
  """

  defparameters name: "Bluetooth"

  defimpl BlueHeron.HCI.Serializable do
    def serialize(%{opcode: opcode, name: name}) do
      padded = for _i <- 1..(248 - byte_size(name)), into: name, do: <<0>>
      <<opcode::binary, 248, padded::binary>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<@opcode::binary, 248, padded::binary>>) do
    new(name: String.trim(padded, <<0>>))
  end

  @impl BlueHeron.HCI.Command
  def deserialize_return_parameters(<<status>>) do
    %{status: status}
  end

  @impl true
  def serialize_return_parameters(%{status: status}) do
    <<BlueHeron.ErrorCode.to_code!(status)>>
  end
end
