defmodule Bluetooth.HCI.Command.ControllerAndBaseband.WriteSecureConnectionsHostSupport do
  use Bluetooth.HCI.Command.ControllerAndBaseband, ocf: 0x007A

  @moduledoc """
  This command writes the Secure_Connections_Host_Support parameter in the BR/EDR Controller.

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`

  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.92

  When Secure Connections Host Support is set to 'enabled' the Controller shall
  use the enhanced reporting mechanisms for the Encryption_Enabled parameter in
  the HCI_Encryption_Change event (see Section 7.7.8) and the Key_Type parameter
  in the HCI_Link_Key_Notification event (see Section 7.7.24). If the Host
  issues this command while the Controller is paging, has page scanning enabled,
  or has an ACL connection, the Controller shall return the error code Command
  Disallowed (0x0C).

  The Link Manager Secure Connections (Host Support) feature bit shall be set to
  the Secure_Connections_Host_Support parameter. The default value for
  Secure_Connections_Host_Support shall be 'disabled.' When
  Secure_Connections_Host_Support is set to 'enabled,' the bit in the LMP
  features mask indicating support for Secure Connections (Host Support) shall
  be set to enabled in subsequent responses to an LMP_FEATURES_REQ from a remote
  device.

  ## Command Parameters
  * `enabled` - boolean

  ## Return Parameters
  * `:status` - see `Bluetooth.ErrorCode`
  * `:status_name` - Friendly status name. see `Bluetooth.ErrorCode`
  """

  defparameters enabled: false

  defimpl Bluetooth.HCI.Serializable do
    def serialize(%{opcode: opcode, enabled: enabled?}) do
      val = if enabled?, do: <<1>>, else: <<0>>
      <<opcode::binary, 1, val::binary>>
    end
  end

  @impl Bluetooth.HCI.Command
  def deserialize(<<@opcode::binary, 1, enabled::binary>>) do
    val = if enabled == <<1>>, do: true, else: false
    %__MODULE__{enabled: val}
  end

  @impl Bluetooth.HCI.Command
  def deserialize_return_parameters(<<status::8>>) do
    %{status: status, status_name: Bluetooth.ErrorCode.name!(status)}
  end

  @impl Bluetooth.HCI.Command
  def serialize_return_parameters(%{status: status}) do
    <<status::8>>
  end
end
