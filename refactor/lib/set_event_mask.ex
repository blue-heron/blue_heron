defmodule BlueHeron.HCI.Commands.SetEventMask do
  @moduledoc """
  Helper module for creating an events bit mask with atom keys
  representing events to include/exclude

  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.1
  """

  import BlueHeron.HCI.Helpers

  @events_map %{
    0 => :inquiry_complete,
    1 => :inquiry_result,
    2 => :connection_complete,
    3 => :connection_request,
    4 => :disconnection_complete,
    5 => :authentication_complete,
    6 => :remote_name_request_complete,
    7 => :encryption_change,
    8 => :change_connection_link_key_complete,
    9 => :master_link_key_complete,
    10 => :read_remote_supported_features_complete,
    11 => :read_remote_version_information_complete,
    12 => :qos_setup_complete,
    15 => :hardware_error,
    16 => :flush_occurred,
    17 => :role_change,
    19 => :mode_change,
    20 => :return_link_keys,
    21 => :pin_code_request,
    22 => :link_key_request,
    23 => :link_key_notification,
    24 => :loopback_command,
    25 => :data_buffer_overflow,
    26 => :max_slots_change,
    27 => :read_clock_offset_complete,
    28 => :connection_packet_type_changed,
    29 => :qos_violation,
    30 => :page_scan_mode_change,
    31 => :page_scan_repetition_mode_change,
    32 => :flow_specification_complete,
    33 => :inquiry_resultwith_rssi,
    34 => :read_remote_extended_features_complete,
    43 => :synchronous_connection_complete,
    44 => :synchronous_connection_changed,
    45 => :sniff_subrating,
    46 => :extended_inquiry_result,
    47 => :encryption_key_refresh_complete,
    48 => :io_capability_request,
    49 => :io_capability_response,
    50 => :user_confirmation_request,
    51 => :user_passkey_request,
    52 => :remote_oob_data_request,
    53 => :simple_pairing_complete,
    55 => :link_supervision_timeout_changed,
    56 => :enhanced_flush_complete,
    58 => :user_passkey_notification,
    59 => :keypress_notification,
    60 => :remote_host_supported_features_notification,
    61 => :le_meta
  }

  def default() do
    for {_bit_pos, key} <- @events_map, into: %{}, do: {key, 1}
  end

  @doc false
  def mask_events(events) when is_binary(events), do: events

  def mask_events(events) when is_list(events) do
    mask_events(Map.new(events))
  end

  def mask_events(events) when is_map(events) do
    for bit_pos <- 0..63, into: <<>> do
      key = @events_map[bit_pos]
      bit = as_uint8(Map.get(events, key, 1))
      <<bit::1>>
    end
  end

  @doc false
  def unmask_events(mask) do
    for {bit_pos, key} <- @events_map, into: %{} do
      {key, ExBin.bit_at(mask, bit_pos)}
    end
  end
end
