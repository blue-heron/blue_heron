# SPDX-FileCopyrightText: 2021 Troels Brødsgaard
# SPDX-FileCopyrightText: 2024 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Command.LEController.SetAdvertisingParameters do
  use BlueHeron.HCI.Command.LEController, ocf: 0x0006

  @moduledoc """
  > The HCI_LE_Set_Scan_Parameters command is used to set the scan parameters.

  Bluetooth Core Version 5.2 | Vol 4, Part E, section 7.8.10

  * OGF: `#{inspect(@ogf, base: :hex)}`
  * OCF: `#{inspect(@ocf, base: :hex)}`
  * Opcode: `#{inspect(@opcode)}`
  """

  defparameters advertising_interval_min: 0x0800,
                advertising_interval_max: 0x0800,
                advertising_type: 0x00,
                own_address_type: 0x00,
                peer_address_type: 0x00,
                peer_address: 0x001122334455,
                advertising_channel_map: 0x07,
                advertising_filter_policy: 0x00

  defimpl BlueHeron.HCI.Serializable do
    def serialize(command) do
      <<
        command.opcode::binary,
        15,
        command.advertising_interval_min::little-16,
        command.advertising_interval_max::little-16,
        command.advertising_type,
        command.own_address_type,
        command.peer_address_type,
        command.peer_address::little-48,
        command.advertising_channel_map,
        command.advertising_filter_policy
      >>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<
        @opcode::binary,
        _fields_size,
        advertising_interval_min::little-16,
        advertising_interval_max::little-16,
        advertising_type,
        own_address_type,
        peer_address_type,
        peer_address::little-48,
        advertising_channel_map,
        advertising_filter_policy
      >>) do
    new(
      advertising_interval_min: advertising_interval_min,
      advertising_interval_max: advertising_interval_max,
      advertising_type: advertising_type,
      own_address_type: own_address_type,
      peer_address_type: peer_address_type,
      peer_address: peer_address,
      advertising_channel_map: advertising_channel_map,
      advertising_filter_policy: advertising_filter_policy
    )
  end

  @impl BlueHeron.HCI.Command
  def deserialize_return_parameters(<<status>>) do
    %{status: status}
  end

  @impl BlueHeron.HCI.Command
  def serialize_return_parameters(%{status: status}) do
    <<BlueHeron.ErrorCode.to_code!(status)>>
  end
end
