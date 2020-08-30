defmodule BlueHeron.HCI.Command.ControllerAndBaseband.ReadLocalName do
  use BlueHeron.HCI.Command.ControllerAndBaseband, ocf: 0x0014

  @moduledoc """
  The Read_Local_Name command provides the ability to read the stored user-friendly name for
  the BR/EDR Controller. See Section 6.23 and 7.3.12 for more details

  * OGF: `0x03`
  * OCF: `0x0014`
  * Opcode: 0xC14

  ## Command Parameters
  > None

  ## Return Parameters
  * `:status` - see `BlueHeron.ErrorCode`
  * `:local_name` - A UTF-8 encoded User Friendly Descriptive Name for the device
  """

  @behaviour BlueHeron.HCI.Command
  defstruct []
  @impl BlueHeron.HCI.Command
  def opcode, do: 0xC14

  @impl BlueHeron.HCI.Command
  def serialize(%__MODULE__{}), do: ""

  @impl BlueHeron.HCI.Command
  def deserialize(<<>>), do: %__MODULE__{}

  @impl BlueHeron.HCI.Command
  def deserialize_return_parameters(<<status::8, local_name::binary>>) do
    %{
      status: status,
      status_name: BlueHeron.ErrorCode.name!(status),
      local_name: String.trim(local_name, <<0>>)
    }
  end

  @impl true
  def serialize_return_parameters(%{status: status, local_name: local_name}) do
    local_name_length = byte_size(local_name)
    pad_length = 248 - local_name_length
    <<status::8, local_name::binary-size(local_name_length), 0::size(pad_length)-unit(8)>>
  end

  @impl true
  def deserialize_return_parameters(<<status::8, local_name::binary>>) do
    %{
      status: BlueHeron.ErrorCode.name!(status),
      # The local name field will fill any remainder of the
      # 248 bytes with null bytes. So just trim those.
      local_name: String.trim(local_name, <<0>>)
    }
  end

  @impl true
  def serialize_return_parameters(%{status: status, local_name: local_name}) do
    name_length = byte_size(local_name)
    padding = 248 - name_length

    <<BlueHeron.ErrorCode.error_code!(status)::8, local_name::binary-size(name_length),
      0::size(padding)-unit(8)>>
  end
end
