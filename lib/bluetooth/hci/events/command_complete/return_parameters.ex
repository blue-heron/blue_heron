defprotocol Bluetooth.HCI.CommandComplete.ReturnParameters do
  @doc """
  Protocol for handling command return_parameters in CommandComplete event

  This is mainly to allow us to do function generation at compile time
  for handling this parsing for specific commands.
  """
  def parse(cc_struct)
end
