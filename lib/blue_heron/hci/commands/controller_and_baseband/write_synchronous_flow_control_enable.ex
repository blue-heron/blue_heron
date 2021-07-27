defmodule BlueHeron.HCI.Command.ControllerAndBaseband.WriteSynchronousFlowControlEnable do
  use BlueHeron.HCI.Command.ControllerAndBaseband, ocf: 0x002F

  @moduledoc """
  This command provides the ability to write the Synchronous_Flow_Control_Enable
  parameter.

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`

  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.37

  The Synchronous_Flow_Control_Enable configuration parameter allows the Host to
  decide if the BR/EDR Controller will send HCI_Number_Of_Completed_Packets
  events for synchronous Connection_Handles. This setting allows the Host to
  enable and disable synchronous flow control.

  The Synchronous_Flow_Control_Enable parameter can only be changed if no
  connections exist.

  ## Command Parameters
  * `enabled` - boolean (default: false)

  ## Return Parameters
  * `:status` - see `BlueHeron.ErrorCode`
  """

  defparameters enabled: false

  defimpl BlueHeron.HCI.Serializable do
    def serialize(%{opcode: opcode, enabled: enabled?}) do
      val = if enabled?, do: <<0x01>>, else: <<0x00>>
      <<opcode::binary, 1, val::binary>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<@opcode::binary, 1, enabled::binary>>) do
    val = if enabled == <<0x01>>, do: true, else: false
    new(enabled: val)
  end

  @impl BlueHeron.HCI.Command
  def deserialize_return_parameters(<<status>>) do
    %{status: status}
  end

  @impl BlueHeron.HCI.Command
  def serialize_return_parameters(%{status: status}) do
    <<BlueHeron.ErrorCode.to_code!(status)>>
  end
end
