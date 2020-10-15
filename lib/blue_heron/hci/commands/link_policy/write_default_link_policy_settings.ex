defmodule BlueHeron.HCI.Command.LinkPolicy.WriteDefaultLinkPolicySettings do
  use BlueHeron.HCI.Command.LinkPolicy, ocf: 0x000F

  @moduledoc """
  This command writes the Default Link Policy configuration value.

  Bluetooth Core Version 5.2 | Vol 4, Part E, section 7.2.12

  The Default_Link_Policy_Settings parameter determines the initial value of the Link_Policy_Settings for all new BR/EDR connections.

  Note: See the Link Policy Settings configuration parameter for more information. See Section 6.18.

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`
  """

  defparameters enable_role_switch: 0, enable_hold_mode: 0, enable_sniff_mode: 0

  defimpl BlueHeron.HCI.Serializable do
    def serialize(data) do
      <<
        data.opcode,
        2,
        0::13,
        data.enable_sniff_mode::1,
        data.enable_hold_mode::1,
        data.enable_role_switch::1
      >>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<@opcode, _size, 0::13, dlps::binary-3-unit(1)>>) do
    <<enable_sniff_mode::1, enable_hold_mode::1, enable_role_switch::1>> = dlps

    %__MODULE__{
      enable_sniff_mode: enable_sniff_mode,
      enable_hold_mode: enable_hold_mode,
      enable_role_switch: enable_role_switch
    }
  end

  @impl BlueHeron.HCI.Command
  def deserialize_return_parameters(<<status>>) do
    %{status: status}
  end

  @impl true
  def serialize_return_parameters(%{status: status}) do
    <<status>>
  end
end
