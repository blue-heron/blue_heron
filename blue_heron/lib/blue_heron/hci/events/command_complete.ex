defmodule BlueHeron.HCI.Event.CommandComplete do
  @behaviour BlueHeron.HCI.Event

  defstruct [:num_hci_command_packets, :opcode, :data]

  @impl BlueHeron.HCI.Event
  def serialize(%__MODULE__{num_hci_command_packets: num, opcode: opcode, data: data})
      when is_binary(data) do
    <<num::8, opcode::little-16, data::binary>>
  end

  def serialize(%__MODULE__{num_hci_command_packets: num, opcode: opcode, data: data}) do
    type = BlueHeron.HCI.Command.implementation_for(opcode)

    unless type,
      do: raise("Can't serialize return paramaters for opcode: #{inspect(opcode, base: :hex)}")

    <<num::8, opcode::little-16, type.serialize_return_parameters(data)::binary>>
  end

  @impl BlueHeron.HCI.Event
  def deserialize(<<num_hci_command_packets::8, opcode::little-16, data::binary>>) do
    command_complete = %__MODULE__{
      num_hci_command_packets: num_hci_command_packets,
      opcode: opcode,
      data: data
    }

    if type = BlueHeron.HCI.Command.implementation_for(opcode) do
      %{command_complete | data: type.deserialize_return_parameters(data)}
    else
      command_complete
    end
  end
end
