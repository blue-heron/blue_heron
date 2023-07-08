defmodule BlueHeron.HCI.Event.CommandComplete do
  use BlueHeron.HCI.Event, code: 0x0E

  @moduledoc """
  > The Command Complete event is used by the Controller for most commands to
  > transmit return status of a command and the other event parameters that are
  > specified for the issued HCI command.

  Reference: Version 5.2, Vol 4, Part E, 7.7.14
  """

  require BlueHeron.HCI.CommandComplete.ReturnParameters
  require Logger

  defparameters [:num_hci_command_packets, :opcode, :return_parameters]

  defimpl BlueHeron.HCI.Serializable do
    def serialize(data) do
      data = BlueHeron.HCI.CommandComplete.ReturnParameters.encode(data)
      bin = <<data.num_hci_command_packets, data.opcode::2-bytes, data.return_parameters::binary>>
      size = byte_size(bin)
      <<data.code, size, bin::binary>>
    end
  end

  defimpl BlueHeron.HCI.CommandComplete.ReturnParameters do
    def decode(cc) do
      %{cc | return_parameters: do_decode(cc.opcode, cc.return_parameters)}
    end

    def encode(cc) do
      %{cc | return_parameters: do_encode(cc.opcode, cc.return_parameters)}
    end

    # Generate return_parameter parsing function for all available command
    # modules based on the requirements in BlueHeron.HCI.Command behaviour
    for mod <- BlueHeron.HCI.Command.__modules__(), opcode = mod.__opcode__() do
      defp do_decode(unquote(opcode), rp_bin) do
        unquote(mod).deserialize_return_parameters(rp_bin)
      end

      defp do_encode(unquote(opcode), rp_map) do
        unquote(mod).serialize_return_parameters(rp_map)
      end
    end

    defp do_encode(_unknown_opcode, data) when is_binary(data), do: data
  end

  @impl BlueHeron.HCI.Event
  def deserialize(<<@code, _size, num_hci_command_packets, opcode::binary-2, rp_bin::binary>>) do
    command_complete = %__MODULE__{
      num_hci_command_packets: num_hci_command_packets,
      opcode: opcode,
      return_parameters: rp_bin
    }

    maybe_decode_return_parameters(command_complete)
  end

  def deserialize(bin), do: {:error, bin}

  def maybe_decode_return_parameters(cc) do
    BlueHeron.HCI.CommandComplete.ReturnParameters.decode(cc)
  catch
    kind, value ->
      Logger.warning("""
      (#{inspect(kind)}, #{inspect(value)}) Unable to decode return_parameters for opcode #{inspect(cc.opcode, base: :hex)}
        return_parameters: #{inspect(cc.return_parameters)}
        #{inspect(__STACKTRACE__, limit: :infinity, pretty: true)}
      """)

      cc
  end
end
