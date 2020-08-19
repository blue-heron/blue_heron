defprotocol Bluetooth.HCI.Serializable do
  @doc """
  Serialize an HCI data structure as a binary
  """
  def serialize(hci_struct)
end
