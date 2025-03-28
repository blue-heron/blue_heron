# SPDX-FileCopyrightText: 2020 Connor Rigby
# SPDX-FileCopyrightText: 2020 Frank Hunleth
# SPDX-FileCopyrightText: 2021 Troels Brødsgaard
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Command.ControllerAndBaseband.SetEventMaskTest do
  use ExUnit.Case
  alias BlueHeron.HCI.Command.ControllerAndBaseband.SetEventMask

  test "unmask_events/1" do
    assert SetEventMask.unmask_events(0x00001FFFFFFFFFFF) ==
             [
               inquiry_complete: true,
               inquiry_result: true,
               connection_complete: true,
               connection_request: true,
               disconnection_complete: true,
               authentication_complete: true,
               remote_name_request_complete: true,
               encryption_change: true,
               change_connection_link_key_complete: true,
               master_link_key_complete: true,
               read_remote_supported_features_complete: true,
               read_remote_version_information_complete: true,
               qos_setup_complete: true,
               hardware_error: true,
               flush_occurred: true,
               role_change: true,
               mode_change: true,
               return_link_keys: true,
               pin_code_request: true,
               link_key_request: true,
               link_key_notification: true,
               loopback_command: true,
               data_buffer_overflow: true,
               max_slots_change: true,
               read_clock_offset_complete: true,
               connection_packet_type_changed: true,
               qos_violation: true,
               page_scan_mode_change: true,
               page_scan_repetition_mode_change: true,
               flow_specification_complete: true,
               inquiry_resultwith_rssi: true,
               read_remote_extended_features_complete: true,
               synchronous_connection_complete: true,
               synchronous_connection_changed: true,
               sniff_subrating: false,
               extended_inquiry_result: false,
               encryption_key_refresh_complete: false,
               io_capability_request: false,
               io_capability_response: false,
               user_confirmation_request: false,
               user_passkey_request: false,
               remote_oob_data_request: false,
               simple_pairing_complete: false,
               link_supervision_timeout_changed: false,
               enhanced_flush_complete: false,
               user_passkey_notification: false,
               keypress_notification: false,
               remote_host_supported_features_notification: false,
               le_meta: false
             ]
  end
end
