# SPDX-FileCopyrightText: 2020 Connor Rigby
# SPDX-FileCopyrightText: 2020 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.ErrorCode do
  @moduledoc """
  Defines all error codes and functions to map between error code and name.

  > When a command fails, or an LMP, LL, or AMP message needs to indicate a failure, error codes
  > are used to indicate the reason for the error. Error codes have a size of one octet.

  Reference: Version 5.0, Vol 2, Part D, 1
  """

  @type name ::
          :unknown_hci_command
          | :unknown_connection_id
          | :hardware_failure
          | :page_timeout
          | :auth_failure
          | :pin_or_key_missing
          | :memory_capacity_exceeded
          | :connection_timeout
          | :connection_limit_exceeded
          | :synchronous_connection_limit_to_a_device_exceeded
          | :connection_already_exists
          | :command_disallowed
          | :connection_rejected_due_to_limited_resources
          | :connection_rejected_due_to_security_reasons
          | :connection_rejected_due_to_unacceptable_bd_addr
          | :connection_accept_timeout_exceeded
          | :unsupported_feature_or_parameter_value
          | :invalid_hci_command_parameters
          | :remote_user_terminated_connection
          | :remote_device_terminated_connection_due_to_low_resources
          | :remote_device_terminated_connection_due_to_power_off
          | :connection_terminated_by_local_host
          | :repeated_attempts
          | :pairing_not_allowed
          | :unknown_lmp_pdu
          | :unsupported_remote_feature
          | :sco_offset_rejected
          | :sco_interval_rejected
          | :sco_air_mode_rejected
          | :invalid_lmp_parameters
          | :unspecified_error
          | :unsupported_lmp_parameter_value
          | :role_change_not_allowed
          | :lmp_response_timeout
          | :lmp_error_transaction_collision
          | :lmp_pdu_not_allowed
          | :encryption_mode_not_acceptable
          | :link_key_cannot_be_changed
          | :requested_qos_not_supported
          | :instant_passed
          | :pairing_with_unit_key_not_supported
          | :different_transaction_collision
          | :reserved
          | :qos_unacceptable_parameter
          | :qos_rejected
          | :channel_classification_not_supported
          | :insufficient_security
          | :parameter_out_of_mandatory_range
          | :reserved
          | :role_switch_pending
          | :reserved
          | :reserved_slot_violation
          | :role_switch_failed
          | :extended_inquiry_response_too_large
          | :secure_simple_pairing_not_supported
          | :host_busy_pairing
          | :connection_rejected_no_suitable_channel
          | :controller_busy
          | :unacceptable_connection_parameters
          | :advertising_timeout
          | :connection_terminated_due_to_mic_failure
          | :connection_failed_to_be_established
          | :mac_connection_failed
          | :course_clock_adjustment_rejected
          | :type0_submap_not_defined
          | :unknown_advertising_identifier
          | :limit_reached
          | :operation_cancelled_by_host
          | :packet_too_long

  # Reference: Version 5.2, Vol 1, Part F, 1.3
  @error_codes [
    {0x00, :ok, "Success"},
    {0x01, :unknown_hci_command, "Unknown HCI Command"},
    {0x02, :unknown_connection_id, "Unknown Connection Identifier"},
    {0x03, :hardware_failure, "Hardware Failure"},
    {0x04, :page_timeout, "Page Timeout"},
    {0x05, :auth_failure, "Authentication Failure"},
    {0x06, :pin_or_key_missing, "PIN or Key Missing"},
    {0x07, :memory_capacity_exceeded, "Memory Capacity Exceeded"},
    {0x08, :connection_timeout, "Connection Timeout"},
    {0x09, :connection_limit_exceeded, "Connection Limit Exceeded"},
    {0x0A, :synchronous_connection_limit_to_a_device_exceeded,
     "Synchronous Connection Limit To A Device Exceeded"},
    {0x0B, :connection_already_exists, "Connection Already Exists"},
    {0x0C, :command_disallowed, "Command Disallowed"},
    {0x0D, :connection_rejected_due_to_limited_resources,
     "Connection Rejected due to Limited Resources"},
    {0x0E, :connection_rejected_due_to_security_reasons,
     "Connection Rejected Due To Security Reasons"},
    {0x0F, :connection_rejected_due_to_unacceptable_bd_addr,
     "Connection Rejected due to Unacceptable BD_ADDR"},
    {0x10, :connection_accept_timeout_exceeded, "Connection Accept Timeout Exceeded"},
    {0x11, :unsupported_feature_or_parameter_value, "Unsupported Feature or Parameter Value"},
    {0x12, :invalid_hci_command_parameters, "Invalid HCI Command Parameters"},
    {0x13, :remote_user_terminated_connection, "Remote User Terminated Connection"},
    {0x14, :remote_device_terminated_connection_due_to_low_resources,
     "Remote Device Terminated Connection due to Low Resources"},
    {0x15, :remote_device_terminated_connection_due_to_power_off,
     "Remote Device Terminated Connection due to Power Off"},
    {0x16, :connection_terminated_by_local_host, "Connection Terminated By Local Host"},
    {0x17, :repeated_attempts, "Repeated Attempts"},
    {0x18, :pairing_not_allowed, "Pairing Not Allowed"},
    {0x19, :unknown_lmp_pdu, "Unknown LMP PDU"},
    {0x1A, :unsupported_remote_feature, "Unsupported Remote Feature / Unsupported LMP Feature"},
    {0x1B, :sco_offset_rejected, "SCO Offset Rejected"},
    {0x1C, :sco_interval_rejected, "SCO Interval Rejected"},
    {0x1D, :sco_air_mode_rejected, "SCO Air Mode Rejected"},
    {0x1E, :invalid_lmp_parameters, "Invalid LMP Parameters / Invalid LL Parameters"},
    {0x1F, :unspecified_error, "Unspecified Error"},
    {0x20, :unsupported_lmp_parameter_value,
     "Unsupported LMP Parameter Value / Unsupported LL Parameter Value"},
    {0x21, :role_change_not_allowed, "Role Change Not Allowed"},
    {0x22, :lmp_response_timeout, "LMP Response Timeout / LL Response Timeout"},
    {0x23, :lmp_error_transaction_collision,
     "LMP Error Transaction Collision / LL Procedure Collision"},
    {0x24, :lmp_pdu_not_allowed, "LMP PDU Not Allowed"},
    {0x25, :encryption_mode_not_acceptable, "Encryption Mode Not Acceptable"},
    {0x26, :link_key_cannot_be_changed, "Link Key cannot be Changed"},
    {0x27, :requested_qos_not_supported, "Requested QoS Not Supported"},
    {0x28, :instant_passed, "Instant Passed"},
    {0x29, :pairing_with_unit_key_not_supported, "Pairing With Unit Key Not Supported"},
    {0x2A, :different_transaction_collision, "Different Transaction Collision"},
    {0x2B, :reserved, "Reserved for Future Use (0x2B)"},
    {0x2C, :qos_unacceptable_parameter, "QoS Unacceptable Parameter"},
    {0x2D, :qos_rejected, "QoS Rejected"},
    {0x2E, :channel_classification_not_supported, "Channel Classification Not Supported"},
    {0x2F, :insufficient_security, "Insufficient Security"},
    {0x30, :parameter_out_of_mandatory_range, "Parameter Out Of Mandatory Range"},
    {0x31, :reserved, "Reserved for Future Use (0x31)"},
    {0x32, :role_switch_pending, "Role Switch Pending"},
    {0x33, :reserved, "Reserved for Future Use (0x33)"},
    {0x34, :reserved_slot_violation, "Reserved Slot Violation"},
    {0x35, :role_switch_failed, "Role Switch Failed"},
    {0x36, :extended_inquiry_response_too_large, "Extended Inquiry Response Too Large"},
    {0x37, :secure_simple_pairing_not_supported, "Secure Simple Pairing Not Supported By Host"},
    {0x38, :host_busy_pairing, "Host Busy - Pairing"},
    {0x39, :connection_rejected_no_suitable_channel,
     "Connection Rejected due to No Suitable Channel Found"},
    {0x3A, :controller_busy, "Controller Busy"},
    {0x3B, :unacceptable_connection_parameters, "Unacceptable Connection Parameters"},
    {0x3C, :advertising_timeout, "Advertising Timeout"},
    {0x3D, :connection_terminated_due_to_mic_failure, "Connection Terminated due to MIC Failure"},
    {0x3E, :connection_failed_to_be_established, "Connection Failed to be Established"},
    {0x3F, :mac_connection_failed, "MAC Connection Failed"},
    {0x40, :course_clock_adjustment_rejected,
     "Coarse Clock Adjustment Rejected but Will Try to Adjust Using Clock Dragging"},
    {0x41, :type0_submap_not_defined, "Type0 Submap Not Defined"},
    {0x42, :unknown_advertising_identifier, "Unknown Advertising Identifier"},
    {0x43, :limit_reached, "Limit Reached"},
    {0x44, :operation_cancelled_by_host, "Operation Cancelled by Host"},
    {0x45, :packet_too_long, "Packet Too Long"}
  ]

  @spec to_atom(non_neg_integer()) :: {0..0xFF, atom, String.t()}
  def to_atom(code) when is_integer(code) do
    List.keyfind(@error_codes, code, 0, :unknown)
  end

  @spec to_code(non_neg_integer() | atom()) :: non_neg_integer() | :error
  def to_code(status) when is_atom(status) do
    List.keyfind(@error_codes, status, 1, :error)
  end

  def to_code(status) when is_integer(status), do: status

  @spec to_code!(non_neg_integer() | atom()) :: non_neg_integer()
  def to_code!(status) do
    case to_code(status) do
      :error -> raise "[#{inspect(__MODULE__)}] No code for #{inspect(status)}"
      code -> code
    end
  end

  @spec to_string(atom()) :: String.t() | :error
  def to_string(atom) when is_atom(atom) do
    List.keyfind(@error_codes, atom, 2, :error)
  end
end
