defmodule Bluetooth.HCI.Command.ControllerAndBaseband.WriteLocalName do
  use Bluetooth.HCI.Command.ControllerAndBaseband, ocf: 0x0013

  @moduledoc """
  The HCI_Write_Local_Name command provides the ability to modify the user- friendly name for the BR/EDR Controller.

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`

  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.11

  ## Command Parameters
  * `name` - A UTF-8 encoded User-Friendly Descriptive Name for the device. Up-to 248 bytes

  ## Return Parameters
  * `:status` - see `Bluetooth.ErrorCode`
  """

  defparameters name: "Bluetooth"

  defimpl Bluetooth.HCI.Serializable do
    def serialize(%{opcode: opcode, name: name}) do
      padded = for _i <- 1..(248 - byte_size(name)), into: name, do: <<0>>
      <<opcode::binary, 248, padded::binary>>
    end
  end

  @impl Bluetooth.HCI.Command
  def deserialize(<<@opcode::binary, 248, padded::binary>>) do
    new(name: String.trim(padded, <<0>>))
  end

  @impl Bluetooth.HCI.Command
  def deserialize_return_parameters(<<status::8>>) do
    %{status: Bluetooth.ErrorCode.name!(status)}
  end

  @impl true
  def serialize_return_parameters(%{status: status}) do
    <<Bluetooth.ErrorCode.error_code!(status)::8>>
  end
end
