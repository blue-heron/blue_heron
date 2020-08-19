defmodule Bluetooth.HCI.Command.LEController.CreateConnection do
  use Bluetooth.HCI.Command.LEController, ocf: 0x000D

  @moduledoc """
  The HCI_LE_Create_Connection command is used to create an ACL connection to a
  connectable advertiser

  Bluetooth Core Version 5.2 | Vol 4, Part E, section 7.8.12

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`

  The LE_Scan_Interval and LE_Scan_Window parameters are recommendations from
  the Host on how long (LE_Scan_Window) and how frequently (LE_Scan_Interval)
  the Controller should scan. The LE_Scan_Window parameter shall be set to a
  value smaller or equal to the value set for the LE_Scan_Interval parameter. If
  both are set to the same value, scanning should run continuously.

  The Initiator_Filter_Policy is used to determine whether the White List is
  used. If the White List is not used, the Peer_Address_Type and the
  Peer_Address parameters specify the address type and address of the
  advertising device to connect to.

  Peer_Address_Type parameter indicates the type of address used in the
  connectable advertisement sent by the peer. The Host shall not set
  Peer_Address_Type to either 0x02 or 0x03 if both the Host and the Controller
  support the HCI_LE_Set_Privacy_Mode command. If a Controller that supports the
  HCI_LE_Set_Privacy_Mode command receives the HCI_LE_Create_Connection command
  with Peer_Address_Type set to either 0x02 or 0x03, it may use either device
  privacy mode or network privacy mode for that peer device.

  Peer_Address parameter indicates the Peer’s Public Device Address, Random
  (static) Device Address, Non-Resolvable Private Address or Resolvable Private
  Address depending on the Peer_Address_Type parameter.

  Own_Address_Type parameter indicates the type of address being used in the
  connection request packets.

  The Connection_Interval_Min and Connection_Interval_Max parameters define the
  minimum and maximum allowed connection interval. The Connection_Interval_Min
  parameter shall not be greater than the Connection_Interval_Max parameter.

  The Connection_Latency parameter defines the maximum allowed connection latency
  (see [Vol 6] Part B, Section 4.5.1).

  The Supervision_Timeout parameter defines the link supervision timeout for the
  connection. The Supervision_Timeout in milliseconds shall be larger than (1 +
  Connection_Latency) * Connection_Interval_Max * 2, where Connection_Interval_Max
  is given in milliseconds. (See [Vol 6] Part B, Section 4.5.2).

  The Min_CE_Length and Max_CE_Length parameters are informative parameters
  providing the Controller with the expected minimum and maximum length of the
  connection events. The Min_CE_Length parameter shall be less than or equal to
  the Max_CE_Length parameter.

  If the Host issues this command when another HCI_LE_Create_Connection command is
  pending in the Controller, the Controller shall return the error code Command
  Disallowed (0x0C).

  If the Own_Address_Type parameter is set to 0x01 and the random address for the
  device has not been initialized, the Controller shall return the error code
  Invalid HCI Command Parameters (0x12).

  If the Own_Address_Type parameter is set to 0x03, the Initiator_Filter_Policy
  parameter is set to 0x00, the controller's resolving list did not contain a
  matching entry, and the random address for the device has not been initialized,
  the Controller shall return the error code Invalid HCI Command Parameters
  (0x12).

  If the Own_Address_Type parameter is set to 0x03, the Initiator_Filter_Policy
  parameter is set to 0x01, and the random address for the device has not been
  initialized, the Controller shall return the error code Invalid HCI Command
  Parameters (0x12)
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

  defimpl Bluetooth.HCI.Serializable do
    def serialize(cc) do
      fields = <<
        cc.le_scan_interval::16-little,
        cc.le_scan_window::16-little,
        cc.initiator_filter_policy::8,
        cc.peer_address_type::8,
        cc.peer_address::48,
        cc.own_address_type::8,
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

  @impl Bluetooth.HCI.Command
  def deserialize(<<@opcode::binary, _fields_size, fields::binary>>) do
    <<
      le_scan_interval::16-little,
      le_scan_window::16-little,
      initiator_filter_policy::8,
      peer_address_type::8,
      peer_address::48,
      own_address_type::8,
      connection_interval_min::16-little,
      connection_interval_max::16-little,
      connection_latency::16-little,
      supervision_timeout::16-little,
      min_ce_length::16-little,
      max_ce_length::16-little
    >> = fields

    cc = %__MODULE__{
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

    {:ok, cc}
  end

  @impl Bluetooth.HCI.Command
  def return_parameters(_), do: %{}
end
