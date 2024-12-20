defmodule BlueHeron.HCI.Command.ControllerAndBaseband.WriteSecureConnectionsHostSupport do
  use BlueHeron.HCI.Command.ControllerAndBaseband, ocf: 0x007A

  @moduledoc """
  > This command writes the Secure_Connections_Host_Support parameter in the BR/EDR
  > Controller.

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`

  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.92
  """

  defparameters enabled: false

  defimpl BlueHeron.HCI.Serializable do
    def serialize(%{opcode: opcode, enabled: enabled?}) do
      val = if enabled?, do: <<1>>, else: <<0>>
      <<opcode::binary, 1, val::binary>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<@opcode::binary, 1, enabled::binary>>) do
    val = if enabled == <<1>>, do: true, else: false
    %__MODULE__{enabled: val}
  end

  @impl BlueHeron.HCI.Command
  def deserialize_return_parameters(<<status>>) do
    %{status: status}
  end

  @impl BlueHeron.HCI.Command
  def serialize_return_parameters(%{status: status}) do
    <<status>>
  end
end
