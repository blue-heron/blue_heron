defprotocol BlueHeron.HCI.CommandComplete.ReturnParameters do
  @doc """
  Protocol for handling command return_parameters in CommandComplete event

  This is mainly to allow us to do function generation at compile time
  for handling this parsing for specific commands.
  """
  def decode(cc_struct)

  def encode(cc_struct)
end
