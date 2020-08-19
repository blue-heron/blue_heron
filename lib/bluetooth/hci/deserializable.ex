defprotocol Bluetooth.HCI.Deserializable do
  @doc """
  Deserialize a binary into HCI data structures
  """
  def deserialize(bin)
end

defimpl Bluetooth.HCI.Deserializable, for: BitString do
  # Define deserialize/1 for HCI.Command modules
  for mod <- Bluetooth.HCI.Command.__modules__(), opcode = mod.__opcode__() do
    def deserialize(unquote(opcode) <> _ = bin) do
      unquote(mod).deserialize(bin)
    end
  end

  # Define deserialize/1 for HCI.Event modules
  for mod <- Bluetooth.HCI.Event.__modules__(), code = mod.__code__() do
    if function_exported?(mod, :__subevent_code__, 0) do
      # These are LEMeta subevents
      def deserialize(
            <<unquote(code), _size, unquote(mod.__subevent_code__()), _rest::binary>> = bin
          ) do
        unquote(mod).deserialize(bin)
      end
    else
      # Normal events
      def deserialize(<<unquote(code), _rest::binary>> = bin) do
        unquote(mod).deserialize(bin)
      end
    end
  end

  def deserialize(bin) do
    error = """
    Unable to deserialize #{inspect(bin, base: :hex)}

    If this is unexpected, then be sure that the target deserialized module
    is defined in the @modules attribute of the appropiate type:

    * Bluetooth.HCI.Command
    * Bluetooth.HCI.Event
    """

    {:error, error}
  end
end
