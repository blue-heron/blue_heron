defmodule BlueHeron.HCI.Events do
  alias BlueHeron.HCI.{Event, RawMessage}

  ##
  # Controller & Baseband Commands
  ##

  @doc """
  """
  @spec decode(RawMessage.t()) :: Event.t()
  def decode(
        %RawMessage{data: <<0x0F, _size, status, num_hci_command_packets, opcode::little-16>>} = e
      ) do
    %Event{
      type: :command_status,
      args: %{num_hci_command_packets: num_hci_command_packets, opcode: opcode, status: status},
      meta: e.meta
    }
  end

  # example
  @spec encode(Event.t()) :: RawMessage.t()
  def encode(%Event{type: :command_status} = e) do
    %RawMessage{
      data: <<0x0F, 4, e.args.status, e.args.num_hci_command_packets, e.args.opcode::little-16>>,
      meta: e.meta
    }
  end
end
