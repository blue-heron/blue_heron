defmodule BlueHeron.HCI.Command.ControllerAndBaseband.WriteLocalName do
  @moduledoc """
  The HCI_Write_Local_Name command provides the ability to modify the user- friendly name for the BR/EDR Controller.

  * OGF: `0x3`
  * OCF: `0x13`
  * Opcode: `0xc13`

  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.11

  ## Command Parameters
  * `name` - A UTF-8 encoded User-Friendly Descriptive Name for the device. Up-to 248 bytes

  ## Return Parameters
  * `:status` - see `BlueHeron.ErrorCode`
  """
  @behaviour BlueHeron.HCI.Command

  defstruct name: "Bluetooth"

  @impl BlueHeron.HCI.Command
  def opcode(), do: 0xC13

  @impl BlueHeron.HCI.Command
  def serialize(%__MODULE__{name: name}) do
    padded = for _i <- 1..(248 - byte_size(name)), into: name, do: <<0>>
    <<padded::binary>>
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<padded::binary>>) do
    %__MODULE__{name: String.trim(padded, <<0>>)}
  end

  @impl BlueHeron.HCI.Command
  def deserialize_return_parameters(<<status::8>>) do
    %{status: status, status_name: BlueHeron.ErrorCode.name!(status)}
  end

  @impl BlueHeron.HCI.Command
  def serialize_return_parameters(%{status: status}) do
    <<status::8>>
  end
end
