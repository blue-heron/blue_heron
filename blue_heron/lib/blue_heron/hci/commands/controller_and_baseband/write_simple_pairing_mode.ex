defmodule BlueHeron.HCI.Command.ControllerAndBaseband.WriteSimplePairingMode do
  @moduledoc """
  This command enables Simple Pairing mode in the BR/EDR Controller.

  * OGF: `0x3`
  * OCF: `0x56`
  * Opcode: `0xc56`

  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.59

  When Simple Pairing Mode is set to 'enabled' the Link Manager shall respond to
  an LMP_IO_CAPABILITY_REQ PDU with an LMP_IO_CAPABILITY_RES PDU and continue
  with the subsequent pairing procedure. When Simple Pairing mode is set to
  'disabled', the Link Manager shall reject an IO capability request. A Host
  shall not set the Simple Pairing Mode to ‘disabled.’

  Until Write_Simple_Pairing_Mode is received by the BR/EDR Controller, it shall
  not support any Simple Pairing sequences, and shall return the error code
  Simple Pairing not Supported by Host (0x37). This command shall be written
  before initiating page scan or paging procedures.

  The Link Manager Secure Simple Pairing (Host Support) feature bit shall be set
  to the Simple_Pairing_Mode parameter. The default value for
  Simple_Pairing_Mode shall be 'disabled.' When Simple_Pairing_Mode is set to
  'enabled,' the bit in the LMP features mask indicating support for Secure
  Simple Pairing (Host Support) shall be set to enabled in subsequent responses
  to an LMP_FEATURES_REQ from a remote device.

  ## Command Parameters
  * `enabled` - boolean to set if pairing mode enabled. Default `false`

  ## Return Parameters
  * `:status` - see `BlueHeron.ErrorCode`
  """
  @behaviour BlueHeron.HCI.Command
  defstruct enabled: false

  @impl BlueHeron.HCI.Command
  def opcode(), do: 0xC56

  @impl BlueHeron.HCI.Command
  def serialize(%__MODULE__{enabled: enabled?}) do
    if enabled?, do: <<1>>, else: <<0>>
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<enabled::binary>>) do
    val = if enabled == <<1>>, do: true, else: false
    %__MODULE__{enabled: val}
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
