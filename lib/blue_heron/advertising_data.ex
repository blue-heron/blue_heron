# SPDX-FileCopyrightText: 2024 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.AdvertisingData do
  @moduledoc """
  Handles building AD structures for AdvertiseingData and ScanResponseData
  """

  @flags 0x01
  @incomplete_list_of_16_bit_service_uuids 0x02
  @complete_list_of_16_bit_service_uuids 0x03

  @incomplete_list_of_32_bit_service_uuids 0x04
  @complete_list_of_32_bit_service_uuids 0x05

  @incomplete_list_of_128_bit_service_uuids 0x06
  @complete_list_of_128_bit_service_uuids 0x07

  @shortened_local_name 0x08

  @complete_local_name 0x09

  @manufacturer_specific_data 0xFF

  @type flag ::
          :le_limited_discoverable_mode
          | :le_general_discoverable_mode
          | :br_edr_not_supported
          | :br_edr_le_supported

  @type ad :: <<_::16, _::_*8>>

  @doc """
  Compose flags AD from a list

      iex()> BlueHeron.AdvertisingData.flags([le_general_discoverable_mode: true, br_edr_not_supported: true])
      <<2, 1, 6>>
  """
  @spec flags([{flag(), boolean()}]) :: ad()
  def flags(list) do
    value =
      Enum.reduce(list, <<0b00000000>>, fn
        {:le_limited_discoverable_mode, value},
        <<0::4, _flag_1::1, flag_2::1, flag_3::1, flag_4::1>> ->
          <<0::4, bit(value)::1, flag_2::1, flag_3::1, flag_4::1>>

        {:le_general_discoverable_mode, value},
        <<0::4, flag_1::1, _flag_2::1, flag_3::1, flag_4::1>> ->
          <<0::4, flag_1::1, bit(value)::1, flag_3::1, flag_4::1>>

        {:br_edr_not_supported, value}, <<0::4, flag_1::1, flag_2::1, _flag_3::1, flag_4::1>> ->
          <<0::4, flag_1::1, flag_2::1, bit(value)::1, flag_4::1>>

        {:br_edr_le_supported, value}, <<0::4, flag_1::1, flag_2::1, flag_3::1, _flag_4::1>> ->
          <<0::4, flag_1::1, flag_2::1, flag_3::1, bit(value)::1>>
      end)

    <<0x02, @flags, value::binary>>
  end

  @doc """
  Compose list of UUIDs AD structure

      iex()> BlueHeron.AdvertisingData.incomplete_list_of_service_uuids([0x12, 0xab])
      <<5, 2, 171, 0, 18, 0>>

      iex()> BlueHeron.AdvertisingData.incomplete_list_of_service_uuids([0xF018E00E0ECE45B09617B744833D89BA])
      <<17, 6, 186, 137, 61, 131, 68, 183, 23, 150, 176, 69, 206, 14, 14, 224, 24,
        240>>
  """
  @spec incomplete_list_of_service_uuids([0 | pos_integer]) :: ad()
  def incomplete_list_of_service_uuids([first | _] = list) when first <= 0xFF do
    list_binary =
      Enum.reduce(list, <<>>, fn
        uuid, acc when uuid <= 0xFF -> <<uuid::little-16>> <> acc
      end)

    <<byte_size(list_binary) + 1, @incomplete_list_of_16_bit_service_uuids, list_binary::binary>>
  end

  def incomplete_list_of_service_uuids([first | _] = list) when first <= 0xFFFF do
    list_binary =
      Enum.reduce(list, <<>>, fn
        uuid, acc when uuid <= 0xFFFF -> <<uuid::little-32>> <> acc
      end)

    <<byte_size(list_binary) + 1, @incomplete_list_of_32_bit_service_uuids, list_binary::binary>>
  end

  def incomplete_list_of_service_uuids(list) do
    list_binary =
      Enum.reduce(list, <<>>, fn
        uuid, acc -> <<uuid::little-128>> <> acc
      end)

    <<byte_size(list_binary) + 1, @incomplete_list_of_128_bit_service_uuids, list_binary::binary>>
  end

  @doc """
  Compose list of UUIDs AD structure

      iex()> BlueHeron.AdvertisingData.complete_list_of_service_uuids([0x12, 0xab])
      <<5, 3, 171, 0, 18, 0>>
  """
  def complete_list_of_service_uuids([first | _] = list) when first <= 0xFF do
    list_binary =
      Enum.reduce(list, <<>>, fn
        uuid, acc when uuid <= 0xFF -> <<uuid::little-16>> <> acc
      end)

    <<byte_size(list_binary) + 1, @complete_list_of_16_bit_service_uuids, list_binary::binary>>
  end

  def complete_list_of_service_uuids([first | _] = list) when first <= 0xFFFF do
    list_binary =
      Enum.reduce(list, <<>>, fn
        uuid, acc when uuid <= 0xFFFF -> <<uuid::little-32>> <> acc
      end)

    <<byte_size(list_binary) + 1, @complete_list_of_32_bit_service_uuids, list_binary::binary>>
  end

  def complete_list_of_service_uuids(list) do
    list_binary =
      Enum.reduce(list, <<>>, fn
        uuid, acc -> <<uuid::little-128>> <> acc
      end)

    <<byte_size(list_binary) + 1, @complete_list_of_128_bit_service_uuids, list_binary::binary>>
  end

  @doc """
  Compose ShortName AD from a string

      iex()> BlueHeron.AdvertisingData.short_name("nerves")
      <<0x7, 0x8, 0x6E, 0x65, 0x72, 0x76, 0x65, 0x73>>
  """
  @spec short_name(String.t()) :: ad()
  def short_name(value) do
    <<byte_size(value) + 1, @shortened_local_name, value::binary-size(byte_size(value))>>
  end

  @doc """
    Compose CompleteName AD from a string

      iex()> BlueHeron.AdvertisingData.complete_name("nerves")
      <<0x7, 0x9, 0x6E, 0x65, 0x72, 0x76, 0x65, 0x73>>
  """
  def complete_name(value) do
    <<byte_size(value) + 1, @complete_local_name, value::binary-size(byte_size(value))>>
  end

  @doc """
  Compose ManufacturerSpecificData AD. Company ID must be encoded in `Value`.

      iex()> ibeacon = BlueHeron.AdvertisingData.IBeacon.new(<<0xF018E00E0ECE45B09617B744833D89BA>>, 1, 2, -50)
      <<76, 0, 2, 21, 186, 0, 1, 0, 2, 206>>
      iex()> BlueHeron.AdvertisingData.manufacturer_specific_data(ibeacon)
      <<11, 255, 76, 0, 2, 21, 186, 0, 1, 0, 2, 206>>
  """
  @spec manufacturer_specific_data(binary()) :: ad()
  def manufacturer_specific_data(value) do
    <<byte_size(value) + 1, @manufacturer_specific_data, value::binary>>
  end

  defp bit(false), do: 0
  defp bit(true), do: 1
end
