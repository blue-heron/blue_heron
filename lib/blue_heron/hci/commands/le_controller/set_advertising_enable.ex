defmodule BlueHeron.HCI.Command.LEController.SetAdvertisingEnable do
  use BlueHeron.HCI.Command.LEController, ocf: 0x000A

  @moduledoc """
  > The HCI_LE_Set_Advertising_Enable command is used to request the Controller
  > to start or stop advertising. The Controller manages the timing of advertisements
  > as per the advertising parameters given in the HCI_LE_Set_Advertising_Parameters
  > command.

  Bluetooth Core Version 5.2 | Vol 4, Part E, section 7.8.9

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`
  """

  defparameters advertising_enable: false

  defimpl BlueHeron.HCI.Serializable do
    def serialize(command) do
      advertising_enable = as_uint8(command.advertising_enable)
      <<command.opcode::binary, 1, advertising_enable>>
    end

    defp as_uint8(true), do: 1
    defp as_uint8(false), do: 0
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<@opcode::binary, _fields_size, advertising_enable>>) do
    new(advertising_enable: as_boolean(advertising_enable))
  end

  @impl BlueHeron.HCI.Command
  def deserialize_return_parameters(<<status>>) do
    %{status: status}
  end

  @impl BlueHeron.HCI.Command
  def serialize_return_parameters(%{status: status}) do
    <<BlueHeron.ErrorCode.to_code!(status)>>
  end

  defp as_boolean(val) when val in [1, "1", true, <<1>>], do: true
  defp as_boolean(_), do: false
end
