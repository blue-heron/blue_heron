defmodule BlueHeron.HCI.Command.ControllerAndBaseband.WriteClassOfDevice do
  @moduledoc """
  This command writes the value for the Class_Of_Device parameter.

  * OGF: `0x3`
  * OCF: `0x24`
  * Opcode: `0xc24`

  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.26

  ## Command Parameters
  * `class` - integer for class of devic

  ## Return Parameters
  * `:status` - see `BlueHeron.ErrorCode`
  """
  @behaviour BlueHeron.HCI.Command

  defstruct class: 0

  @impl BlueHeron.HCI.Command
  def opcode(), do: 0xC24

  @impl BlueHeron.HCI.Command
  def serialize(%{class: class}) do
    <<class::24>>
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<class::24>>) do
    %__MODULE__{class: class}
  end

  @impl BlueHeron.HCI.Command
  def deserialize_return_parameters(<<status::8>>) do
    %{status: BlueHeron.ErrorCode.name!(status)}
  end

  @impl true
  def serialize_return_parameters(%{status: status}) do
    <<BlueHeron.ErrorCode.error_code!(status)::8>>
  end
end
