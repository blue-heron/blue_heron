# SPDX-FileCopyrightText: 2021 Troels Brødsgaard
# SPDX-FileCopyrightText: 2024 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.ATT.ReadBlobRequest do
  @moduledoc """
  > The ATT_READ_BLOB_REQ PDU is used to request the server to read part of the
  > value of an attribute at a given offset and return a specific part of the value in an
  > ATT_READ_BLOB_RSP PDU.

  Bluetooth Spec v5.2, vol 3, Part F, 3.4.4.5
  """

  defstruct [:opcode, :handle, :offset]

  def serialize(%{handle: handle, offset: offset}) do
    <<0x0C, handle::little-16, offset::little-16>>
  end

  def deserialize(<<0x0C, handle::little-16, offset::little-16>>) do
    %__MODULE__{
      opcode: 0x0C,
      handle: handle,
      offset: offset
    }
  end
end
