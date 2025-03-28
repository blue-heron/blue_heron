# SPDX-FileCopyrightText: 2020 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.AddressTest do
  use ExUnit.Case
  doctest BlueHeron.Address
  alias BlueHeron.Address

  test "from integer" do
    address = Address.parse(0xA4C138A0498B)
    assert address.integer == 0xA4C138A0498B
    assert address.binary == <<0xA4, 0xC1, 0x38, 0xA0, 0x49, 0x8B>>
    assert address.string == "A4:C1:38:A0:49:8B"
  end

  test "from string" do
    address = Address.parse("A4:C1:38:A0:49:8B")
    assert address.integer == 0xA4C138A0498B
    assert address.binary == <<0xA4, 0xC1, 0x38, 0xA0, 0x49, 0x8B>>
    assert address.string == "A4:C1:38:A0:49:8B"
  end

  test "from binary" do
    address = Address.parse(<<0xA4, 0xC1, 0x38, 0xA0, 0x49, 0x8B>>)
    assert address.integer == 0xA4C138A0498B
    assert address.binary == <<0xA4, 0xC1, 0x38, 0xA0, 0x49, 0x8B>>
    assert address.string == "A4:C1:38:A0:49:8B"
  end

  test "to_string" do
    address_from_integer = Address.parse(0xA4C138A0498B)
    address_from_string = Address.parse("A4:C1:38:A0:49:8B")
    address_from_binary = Address.parse(<<0xA4, 0xC1, 0x38, 0xA0, 0x49, 0x8B>>)

    assert to_string(address_from_integer) == "A4:C1:38:A0:49:8B"
    assert to_string(address_from_string) == "A4:C1:38:A0:49:8B"
    assert to_string(address_from_binary) == "A4:C1:38:A0:49:8B"
  end

  test "inspect" do
    address_from_integer = Address.parse(0xA4C138A0498B)
    address_from_string = Address.parse("A4:C1:38:A0:49:8B")
    address_from_binary = Address.parse(<<0xA4, 0xC1, 0x38, 0xA0, 0x49, 0x8B>>)

    inspect(to_string(address_from_integer) == "Address<A4:C1:38:A0:49:8B>")
    inspect(to_string(address_from_string) == "Address<A4:C1:38:A0:49:8B>")
    inspect(to_string(address_from_binary) == "Address<A4:C1:38:A0:49:8B>")
  end
end
