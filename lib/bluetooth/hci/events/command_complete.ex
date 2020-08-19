defmodule Bluetooth.HCI.Event.CommandComplete do
  use Bluetooth.HCI.Event, code: 0x0E

  @moduledoc """
  > The Command Complete event is used by the Controller for most commands to
  > transmit return status of a command and the other event parameters that are
  > specified for the issued HCI command.

  Reference: Version 5.2, Vol 4, Part E, 7.7.14
  """

  require Bluetooth.HCI.CommandComplete.ReturnParameters
  require Logger

  defparameters [:num_hci_command_packets, :opcode, :return_parameters]

  defimpl Bluetooth.HCI.Serializable do
    def serialize(data) do
      bin = <<
        data.num_hci_command_packets::8,
        data.opcode::16,
        data.return_parameters::binary
      >>

      size = byte_size(bin)

      <<data.code::binary, size, bin::binary>>
    end
  end

  @impl Bluetooth.HCI.Event
  def deserialize(<<@code, _size, num_hci_command_packets::8, opcode::binary-2, rp_bin::binary>>) do
    command_complete = %__MODULE__{
      num_hci_command_packets: num_hci_command_packets,
      opcode: opcode,
      return_parameters: rp_bin
    }

    maybe_parse_return_parameters(command_complete)
  end

  def deserialize(bin), do: {:error, bin}

  def maybe_parse_return_parameters(cc) do
    Bluetooth.HCI.CommandComplete.ReturnParameters.parse(cc)
  catch
    kind, value ->
      Logger.warn("""
      (#{inspect(kind)}, #{inspect(value)}) Unable to parse return_parameters for opcode #{
        inspect(cc.opcode)
      }
        return_parameters: #{inspect(cc.return_parameters)}
      """)

      cc
  end
end
