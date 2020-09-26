defmodule BlueHeron.Address do
  @moduledoc """
  Helper struct for working with BLE Addresses.
  """

  alias BlueHeron.Address

  defstruct string: "00:00:00:00:00:00",
            binary: <<00, 00, 00, 00, 00, 00>>,
            integer: 0x000000000000

  defimpl Inspect do
    def inspect(address, _opts) do
      "#BlueHeron.Address<#{address.string}>"
    end
  end

  defimpl String.Chars do
    def to_string(address) do
      address.string
    end
  end

  @doc """
  Parses an Address from a colon delimited BLE address string
  Examples:

      iex> BlueHeron.Address.parse("A4:C1:38:A0:49:8B")
      #BlueHeron.Address<A4:C1:38:A0:49:8B>

      iex> BlueHeron.Address.parse(0xA4C138A0498B)
      #BlueHeron.Address<A4:C1:38:A0:49:8B>

      iex> BlueHeron.Address.parse(181149785672075)
      #BlueHeron.Address<A4:C1:38:A0:49:8B>

      iex> BlueHeron.Address.parse(<<0xA4, 0xC1, 0x38, 0xA0, 0x49, 0x8B>>)
      #BlueHeron.Address<A4:C1:38:A0:49:8B>

      iex> BlueHeron.Address.parse(<<164, 193, 56, 160, 73, 139>>)
      #BlueHeron.Address<A4:C1:38:A0:49:8B>

  """
  def parse(
        <<oct1::binary-2, ":", oct2::binary-2, ":", oct3::binary-2, ":", oct4::binary-2, ":",
          oct5::binary-2, ":", oct6::binary-2>> = string
      ) do
    addr = String.to_integer(IO.iodata_to_binary([oct1, oct2, oct3, oct4, oct5, oct6]), 16)

    %Address{
      string: string,
      binary: <<addr::48>>,
      integer: addr
    }
  end

  def parse(addr) when addr <= 0xFFFFFFFFFFFF do
    <<oct1, oct2, oct3, oct4, oct5, oct6>> = <<addr::48>>

    string = format_iodata([oct1, oct2, oct3, oct4, oct5, oct6])

    %Address{
      string: string,
      binary: <<addr::48>>,
      integer: addr
    }
  end

  def parse(<<oct1, oct2, oct3, oct4, oct5, oct6>> = binary) do
    <<addr::48>> = binary
    string = format_iodata([oct1, oct2, oct3, oct4, oct5, oct6])

    %Address{
      string: string,
      binary: binary,
      integer: addr
    }
  end

  defp format_iodata(iodata) do
    to_string(:io_lib.format('~2.16.0B:~2.16.0B:~2.16.0B:~2.16.0B:~2.16.0B:~2.16.0B', iodata))
  end
end
