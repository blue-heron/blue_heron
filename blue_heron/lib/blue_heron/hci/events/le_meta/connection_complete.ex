defmodule BlueHeron.HCI.Event.LEMeta.ConnectionComplete do
  @moduledoc """
  The HCI_LE_Connection_Complete event indicates to both of the Hosts forming
  the connection that a new connection has been created.

  Upon the creation of the connection a Connection_Handle shall be assigned by
  the Controller, and passed to the Host in this event. If the connection
  creation fails this event shall be provided to the Host that had issued the
  HCI_LE_Create_Connection command.

  This event indicates to the Host which issued an HCI_LE_Create_Connection
  command and received an HCI_Command_Status event if the connection creation
  failed or was successful.

  The Master_Clock_Accuracy parameter is only valid for a slave. On a master,
  this parameter shall be set to 0x00.

  Note: This event is not sent if the HCI_LE_Enhanced_Connection_Complete event
  (see Section 7.7.65.10) is unmasked.

  Reference: Version 5.2, Vol 4, Part E, 7.7.65.1
  """

  @behaviour BlueHeron.HCI.Event

  defstruct [
    :status,
    :status_name,
    :connection_handle,
    :role,
    :peer_address_type,
    :peer_address,
    :connection_interval,
    :connection_latency,
    :supervision_timeout,
    :master_clock_accuracy
  ]

  @impl BlueHeron.HCI.Event
  def serialize(cc) do
    <<
      cc.status::8,
      cc.connection_handle::little-16,
      cc.role,
      cc.peer_address_type,
      cc.peer_address::48,
      cc.connection_interval::little-16,
      cc.connection_latency::little-16,
      cc.supervision_timeout::little-16,
      cc.master_clock_accuracy
    >>
  end

  @impl BlueHeron.HCI.Event
  def deserialize(bin) do
    <<
      status,
      connection_handle::little-12,
      _::4,
      role,
      peer_address_type,
      peer_address::48,
      connection_interval::little-16,
      connection_latency::little-16,
      supervision_timeout::little-16,
      master_clock_accuracy
    >> = bin

    %__MODULE__{
      status: status,
      status_name: BlueHeron.ErrorCode.name!(status),
      connection_handle: connection_handle,
      role: role,
      peer_address_type: peer_address_type,
      peer_address: peer_address,
      connection_interval: connection_interval,
      connection_latency: connection_latency,
      supervision_timeout: supervision_timeout,
      master_clock_accuracy: master_clock_accuracy
    }
  end
end
