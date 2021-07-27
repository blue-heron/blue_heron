defmodule BlueHeron.HCI.Command.ControllerAndBaseband.WriteDefaultErroneousDataReporting do
  use BlueHeron.HCI.Command.ControllerAndBaseband, ocf: 0x005B

  @moduledoc """
  This command writes the Erroneous_Data_Reporting parameter.

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`

  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.65

  This command writes the Erroneous_Data_Reporting parameter. The BR/EDR
  Controller shall set the Packet_Status_Flag as defined in Section 5.4.3 HCI
  Synchronous Data packets, depending on the value of this parameter. The new
  value for the Erroneous_Data_Reporting parameter shall not apply to existing
  synchronous connections.

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
