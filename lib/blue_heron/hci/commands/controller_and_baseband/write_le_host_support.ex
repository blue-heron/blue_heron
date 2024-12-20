defmodule BlueHeron.HCI.Command.ControllerAndBaseband.WriteLEHostSupport do
  use BlueHeron.HCI.Command.ControllerAndBaseband, ocf: 0x006D

  @moduledoc """
  > The HCI_Write_LE_Host_Support command is used to set the LE Supported (Host)
  > Link Manager Protocol feature bi

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`

  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.79
  """

  defparameters le_supported_host_enabled: false

  defimpl BlueHeron.HCI.Serializable do
    def serialize(%{opcode: opcode, le_supported_host_enabled: le_supported_host_enabled?}) do
      val = if le_supported_host_enabled?, do: <<0x01>>, else: <<0x00>>
      <<opcode::binary, 2, val::binary, 0x00>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<@opcode::binary, 2, le_supported_host_enabled::binary-1, 0x00>>) do
    val = if le_supported_host_enabled == <<0x01>>, do: true, else: false
    new(le_supported_host_enabled: val)
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
