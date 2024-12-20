defmodule BlueHeron.HCI.Command.LEController.LongTermKeyRequestReply do
  use BlueHeron.HCI.Command.LEController, ocf: 0x001A

  @moduledoc """
  > The HCI_LE_Long_Term_Key_Request_Reply command is used to reply to an
  > HCI_LE_Long_Term_Key_Request event from the Controller, and specifies the
  > Long_Term_Key parameter that shall be used for this Connection_Handle.
  > This command shall only be used when the local device’s role is Peripheral.

  Bluetooth Core Version 5.2 | Vol 4, Part E, section 7.8.25

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`
  """

  defparameters [
    :connection_handle,
    :ltk
  ]

  defimpl BlueHeron.HCI.Serializable do
    def serialize(%{opcode: opcode, connection_handle: handle, ltk: ltk}) do
      bin = <<handle::little-16>> <> ltk
      <<opcode::binary, 18, bin::binary>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<@opcode::binary, 18, lower_handle, _::4, upper_handle::4, ltk::binary>>) do
    <<handle::little-12>> = <<lower_handle, upper_handle::4>>

    %__MODULE__{
      opcode: @opcode,
      connection_handle: handle,
      ltk: ltk
    }
  end

  @impl BlueHeron.HCI.Command
  def deserialize_return_parameters(<<status, lower_handle, _::4, upper_handle::4>>) do
    <<handle::little-12>> = <<lower_handle, upper_handle::4>>
    %{status: status, connection_handle: handle}
  end

  @impl BlueHeron.HCI.Command
  def serialize_return_parameters(%{status: status, connection_handle: handle}) do
    <<BlueHeron.ErrorCode.to_code!(status), handle::little-16>>
  end
end
