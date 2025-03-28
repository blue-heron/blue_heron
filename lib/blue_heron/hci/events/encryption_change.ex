# SPDX-FileCopyrightText: 2023 Markus Hutzler
# SPDX-FileCopyrightText: 2025 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Event.EncryptionChange do
  use BlueHeron.HCI.Event, code: 0x08

  @moduledoc """
  The HCI_Encryption_Change event is used to indicate that the change of the
  encryption mode has been completed. The Connection_Handle event
  parameter will be a Connection_Handle for an ACL connection and is used to
  identify the remote device.

  Reference: Version 5.4, Vol 4, Part E, 7.7.8
  """

  defparameters [
    :status,
    :connection_handle,
    :encryption_enabled
  ]

  defimpl BlueHeron.HCI.Serializable do
    def serialize(data) do
      <<lower_handle, upper_handle::4>> = <<data.connection_handle::little-12>>
      handle = <<lower_handle, 0::4, upper_handle::4>>

      bin = <<
        data.status,
        handle::binary,
        data.encryption_enabled
      >>

      size = byte_size(bin)
      <<data.code, size, bin::binary>>
    end
  end

  @impl BlueHeron.HCI.Event
  def deserialize(
        <<@code, _size,
          <<
            status,
            lower_handle,
            _::4,
            upper_handle::4,
            encryption_enabled
          >>::binary>>
      ) do
    <<handle::little-12>> = <<lower_handle, upper_handle::4>>

    %__MODULE__{
      status: status,
      connection_handle: handle,
      encryption_enabled: encryption_enabled
    }
  end

  def deserialize(bin), do: {:error, bin}
end
