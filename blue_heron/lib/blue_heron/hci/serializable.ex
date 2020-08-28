defprotocol BlueHeron.HCI.Serializable do
  @doc """
  Serialize an HCI data structure as a binary
  """
  def serialize(hci_struct)
end

defimpl BlueHeron.HCI.Serializable, for: BitString do
  # If its already serialized, pass it on
  def serialize(data), do: data
end
