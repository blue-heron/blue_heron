defmodule BlueHeron.HCIDump do
  @moduledoc """
  Interface to writing/reading PKTLOG formatted data
  """

  alias BlueHeron.HCIDump.PKTLOG

  @doc """
  Encodes a PKTLOG packet
  """
  def encode(%PKTLOG{type: type} = pkt, direction) do
    payload_length = 13 - 4 + byte_size(pkt.payload)
    type = encode_type(type, direction)
    <<payload_length::32, pkt.tv_sec::32, pkt.tv_us::32, type>> <> pkt.payload
  end

  @doc "Decode a file that contains PKTLOG packets"
  def decode_file!(path) do
    decode_bin(File.read!(path), [])
  end

  @doc """
  Decode an array of PKTLOG packets
  """
  def decode_bin(<<length::32, sec::32, us::32, type, rest::binary>>, acc) do
    payload_length = length - 13 + 4
    <<payload::binary-size(payload_length), rest::binary>> = rest
    type = decode_type(type)
    payload = decode_payload(payload, type)
    decode_bin(rest, [%PKTLOG{tv_sec: sec, tv_us: us, type: type, payload: payload} | acc])
  end

  def decode_bin(<<>>, acc), do: Enum.reverse(acc)

  defp decode_type(0x00), do: :HCI_COMMAND_DATA_PACKET
  defp decode_type(0x03), do: :HCI_ACL_DATA_PACKET
  defp decode_type(0x02), do: :HCI_ACL_DATA_PACKET
  defp decode_type(0x09), do: :HCI_SCO_DATA_PACKET
  defp decode_type(0x08), do: :HCI_SCO_DATA_PACKET
  defp decode_type(0x01), do: :HCI_EVENT_PACKET
  defp decode_type(0xFC), do: :LOG_MESSAGE_PACKET
  defp decode_type(int), do: int

  defp decode_payload(payload, _type), do: payload

  defp encode_type(int, _) when int <= 255, do: int

  defp encode_type(:HCI_COMMAND_DATA_PACKET, _), do: 0x00

  defp encode_type(:HCI_ACL_DATA_PACKET, :in), do: 0x03
  defp encode_type(:HCI_ACL_DATA_PACKET, :out), do: 0x02

  defp encode_type(:HCI_SCO_DATA_PACKET, :in), do: 0x09
  defp encode_type(:HCI_SCO_DATA_PACKET, :out), do: 0x08

  defp encode_type(:HCI_EVENT_PACKET, _), do: 0x01
  defp encode_type(:LOG_MESSAGE_PACKET, _), do: 0xFC
end
