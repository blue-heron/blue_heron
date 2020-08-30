defmodule BlueHeron.HCI.Command.ControllerAndBaseband.Reset do
  @moduledoc """
  Reset the baseband

  * OGF: `0x3`
  * OCF: `0x3`
  * Opcode: `0xC03`

  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.2

  The `HCI_Reset` command will reset the Controller and the Link Manager on the BR/EDR Controller, the PAL on an AMP Controller, or the Link Layer on an LE Controller. If the Controller supports both BR/EDR and LE then the HCI_Reset command shall reset the Link Manager, Baseband and Link Layer. The HCI_Reset command shall not affect the used HCI transport layer since the HCI transport layers may have reset mechanisms of their own. After the reset is completed, the current operational state will be lost, the Controller will enter standby mode and the Controller will automatically revert to the default values for the parameters for which default values are defined in the specification.

  Note: The HCI_Reset command will not necessarily perform a hardware reset. This is implementation defined.

  On an AMP Controller, the HCI_Reset command shall reset the service provided at the logical HCI to its initial state, but beyond this the exact effect on the Controller device is implementation defined and should not interrupt the service provided to other protocol stacks.

  The Host shall not send additional HCI commands before the HCI_Command_Complete event related to the HCI_Reset command has been received.

  ## Command Parameters
  > None

  ## Return Parameters
  * `:status` - see `BlueHeron.ErrorCode`
  """
  @behaviour BlueHeron.HCI.Command
  defstruct []

  @impl BlueHeron.HCI.Command
  def opcode(), do: 0xC03

  @impl BlueHeron.HCI.Command
  def serialize(%__MODULE__{}), do: ""

  @impl BlueHeron.HCI.Command
  def deserialize(_), do: %__MODULE__{}

  @impl BlueHeron.HCI.Command
  def deserialize_return_parameters(<<status::8>>) do
    %{status: status, status_name: BlueHeron.ErrorCode.name!(status)}
  end

  @impl BlueHeron.HCI.Command
  def serialize_return_parameters(%{status: status}) do
    <<status::8>>
  end
end
