# SPDX-FileCopyrightText: 2020 Connor Rigby
# SPDX-FileCopyrightText: 2021 Troels Brødsgaard
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.ACL do
  @moduledoc """
  > HCI ACL Data packets are used to exchange data between the Host and Controller

  Bluetooth Spec v5.2, vol 4, Part E, 5.4.2
  """
  alias BlueHeron.ACL
  require Logger

  defstruct [:handle, :flags, :data]

  def deserialize(
        <<handle_and_flags::little-16, length::little-16, acl_data::binary-size(length)>>
      ) do
    <<bc::2, pb::2, handle::12>> = <<handle_and_flags::16>>
    data = BlueHeron.L2Cap.deserialize(acl_data)

    %ACL{
      handle: handle,
      flags: %{pb: pb, bc: bc},
      data: data
    }
  end

  def deserialize(data) do
    Logger.warning("ACL deserialize failed for: #{inspect(data, base: :hex, limit: 60)}")
    nil
  end

  def serialize(%ACL{data: %type{} = data} = acl) do
    serialize(%{acl | data: type.serialize(data)})
  end

  def serialize(%ACL{data: data, handle: handle, flags: %{pb: pb, bc: bc}}) do
    length = byte_size(data)
    <<handle_and_flags::16>> = <<bc::2, pb::2, handle::12>>
    <<handle_and_flags::little-16, length::little-16, data::binary-size(length)>>
  end

  def serialize(binary) when is_binary(binary), do: binary
end
