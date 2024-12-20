defmodule BlueHeron.HCI.Command.LEController.ReadWhiteListSize do
  use BlueHeron.HCI.Command.LEController, ocf: 0x000F

  @moduledoc """
  > The HCI_LE_Read_Filter_Accept_List_Size command is used to read the total number
  > of Filter Accept List entries that can be stored in the Controller.
  > Note: The number of entries that can be stored is not fixed and the Controller can
  > change it at any time (e.g. because the memory used to store the Filter Accept List can
  > also be used for other purposes).

  Bluetooth Core Version 5.2 | Vol 4, Part E, section 7.8.14

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`
  """

  defparameters []

  defimpl BlueHeron.HCI.Serializable do
    def serialize(%{opcode: opcode}) do
      <<opcode::binary, 0x00>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<@opcode::binary, 0x00>>) do
    new()
  end

  @impl BlueHeron.HCI.Command
  def deserialize_return_parameters(<<status, white_list_size>>) do
    %{
      status: status,
      white_list_size: white_list_size
    }
  end

  @impl BlueHeron.HCI.Command
  def serialize_return_parameters(%{status: status, white_list_size: white_list_size}) do
    <<BlueHeron.ErrorCode.to_code!(status), white_list_size>>
  end
end
