# SPDX-FileCopyrightText: 2023 Markus Hutzler
# SPDX-FileCopyrightText: 2024 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Event.LEMeta.LongTermKeyRequest do
  use BlueHeron.HCI.Event.LEMeta, subevent_code: 0x05

  @moduledoc """
  > The HCI_LE_Long_Term_Key_Request event indicates that the peer device, in
  > the Central role, is attempting to encrypt or re-encrypt the link and is requesting
  > the Long Term Key from the Host. (See [Vol 6] Part B, Section 5.1.3).

  Reference: Version 5.3, Vol 4, Part E, 7.7.65.5
  """

  defparameters [
    :subevent_code,
    :connection_handle,
    :random_number,
    :encrypted_diversifier
  ]

  defimpl BlueHeron.HCI.Serializable do
    def serialize(data) do
      <<lower_handle, upper_handle::4>> = <<data.connection_handle::little-12>>
      handle = <<lower_handle, 0::4, upper_handle::4>>

      bin = <<
        data.subevent_code,
        data.status,
        handle::binary,
        data.random_number::little-64,
        data.encrypted_diversifier::little-16
      >>

      size = byte_size(bin)

      <<data.code, size, bin::binary>>
    end
  end

  @impl BlueHeron.HCI.Event
  def deserialize(<<@code, _size, @subevent_code, bin::binary>>) do
    <<
      lower_handle,
      _::4,
      upper_handle::4,
      random_number::little-64,
      encrypted_diversifier::little-16
    >> = bin

    <<handle::little-12>> = <<lower_handle, upper_handle::4>>

    %__MODULE__{
      subevent_code: @subevent_code,
      connection_handle: handle,
      random_number: random_number,
      encrypted_diversifier: encrypted_diversifier
    }
  end

  def deserialize(bin), do: {:error, bin}
end
