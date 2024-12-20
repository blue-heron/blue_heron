defmodule BlueHeron.HCI.Command.LEController.SetAdvertisingData do
  use BlueHeron.HCI.Command.LEController, ocf: 0x0008

  @moduledoc """
  > The HCI_LE_Set_Advertising_Data command is used to set the data used in
  > advertising packets that have a data field.

  Bluetooth Core Version 5.2 | Vol 4, Part E, section 7.8.7

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`
  """

  defparameters advertising_data: <<>>

  defimpl BlueHeron.HCI.Serializable do
    def serialize(%{opcode: opcode, advertising_data: advertising_data})
        when byte_size(advertising_data) <= 31 do
      length = byte_size(advertising_data)
      padding_size = (31 - length) * 8

      <<opcode::binary, 32, length, advertising_data::binary, 0::size(padding_size)>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(
        <<@opcode::binary, 32, length, advertising_data::binary-size(length), _rest::binary>>
      ) do
    new(advertising_data: advertising_data)
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
