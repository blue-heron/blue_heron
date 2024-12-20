defmodule BlueHeron.ACL do
  @moduledoc """
  > HCI ACL Data packets are used to exchange data between the Host and Controller

  Bluetooth Spec v5.2, vol 4, Part E, 5.4.2
  """
  alias BlueHeron.ACL
  require Logger

  defstruct [:handle, :flags, :data]

  def deserialize(
        <<handle::little-12, pb::2, bc::2, length::little-16, acl_data::binary-size(length)>>
      ) do
    data = BlueHeron.L2Cap.deserialize(acl_data)

    %ACL{
      handle: handle,
      flags: %{pb: pb, bc: bc},
      data: data
    }
  end

  def serialize(%ACL{data: %type{} = data} = acl) do
    serialize(%{acl | data: type.serialize(data)})
  end

  def serialize(%ACL{data: data, handle: handle, flags: %{pb: pb, bc: bc}}) do
    length = byte_size(data)
    <<handle::little-12, pb::2, bc::2, length::little-16, data::binary-size(length)>>
  end

  def serialize(binary) when is_binary(binary), do: binary
end
