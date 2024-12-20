defmodule BlueHeron.HCI.Command.LEController.CreateConnectionCancel do
  use BlueHeron.HCI.Command.LEController, ocf: 0x000E

  @moduledoc """
  > The HCI_LE_Create_Connection_Cancel command is used to cancel the
  > HCI_LE_Create_Connection or HCI_LE_Extended_Create_Connection commands.
  > If no HCI_LE_Create_Connection or HCI_LE_Extended_Create_Connection command
  > is pending, then the Controller shall return the error code Command Disallowed (0x0C).

  Bluetooth Core Version 5.2 | Vol 4, Part E, section 7.8.13

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`
  """

  defparameters([])

  defimpl BlueHeron.HCI.Serializable do
    def serialize(%{opcode: opcode}) do
      <<opcode::binary, 0>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<@opcode::binary, 0>>) do
    # This is a pretty useless function because there aren't
    # any parameters to actually parse out of this, but we
    # can at least assert its correct with matching
    %__MODULE__{}
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
