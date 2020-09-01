defmodule BlueHeron.HCI.Commands.ReturnParameters do
  import BlueHeron.HCI.Helpers, only: [decode_status!: 1]

  @doc """
  Helper module for parsing HCI command return parameters in HCI_Command_Complete events.

  See each commands definition for return parameters definitions
  """

  # HCI_Read_Local_Name
  def decode(<<20, 12, status::8, local_name::binary>>) do
    # The local name field will fill any remainder of the
    # 248 bytes with null bytes. So just trim those.
    decode_status!(status)
    |> Map.put(:local_name, String.trim(local_name, <<0>>))
  end

  def decode(<<_opcode::16, rp_bin::binary>>), do: rp_bin
end
