defmodule BlueHeron.HCI.Command.LEController.CreateConnection do
  use BlueHeron.HCI.Command.LEController, ocf: 0x000D

  @moduledoc """
  > The HCI_LE_Create_Connection command is used to create an ACL connection to a
  > connectable advertiser

  Bluetooth Core Version 5.2 | Vol 4, Part E, section 7.8.12

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`
  """

  defparameters le_scan_interval: 0x0C80,
                le_scan_window: 0x0640,
                initiator_filter_policy: 0,
                peer_address_type: 0,
                peer_address: nil,
                own_address_type: 0,
                connection_interval_min: 0x0024,
                connection_interval_max: 0x0C80,
                connection_latency: 0x0012,
                supervision_timeout: 0x0640,
                min_ce_length: 0x0006,
                max_ce_length: 0x0054

  defimpl BlueHeron.HCI.Serializable do
    def serialize(cc) do
      fields = <<
        cc.le_scan_interval::16-little,
        cc.le_scan_window::16-little,
        cc.initiator_filter_policy,
        cc.peer_address_type,
        cc.peer_address::little-48,
        cc.own_address_type,
        cc.connection_interval_min::16-little,
        cc.connection_interval_max::16-little,
        cc.connection_latency::16-little,
        cc.supervision_timeout::16-little,
        cc.min_ce_length::16-little,
        cc.max_ce_length::16-little
      >>

      fields_size = byte_size(fields)

      <<cc.opcode::binary, fields_size, fields::binary>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<@opcode::binary, _fields_size, fields::binary>>) do
    <<
      le_scan_interval::16-little,
      le_scan_window::16-little,
      initiator_filter_policy,
      peer_address_type,
      peer_address::48,
      own_address_type,
      connection_interval_min::16-little,
      connection_interval_max::16-little,
      connection_latency::16-little,
      supervision_timeout::16-little,
      min_ce_length::16-little,
      max_ce_length::16-little
    >> = fields

    %__MODULE__{
      le_scan_interval: le_scan_interval,
      le_scan_window: le_scan_window,
      initiator_filter_policy: initiator_filter_policy,
      peer_address_type: peer_address_type,
      peer_address: peer_address,
      own_address_type: own_address_type,
      connection_interval_min: connection_interval_min,
      connection_interval_max: connection_interval_max,
      connection_latency: connection_latency,
      supervision_timeout: supervision_timeout,
      min_ce_length: min_ce_length,
      max_ce_length: max_ce_length
    }
  end

  @impl BlueHeron.HCI.Command
  def serialize_return_parameters(binary), do: binary

  @impl BlueHeron.HCI.Command
  def deserialize_return_parameters(binary) when is_binary(binary) do
    binary
  end
end
