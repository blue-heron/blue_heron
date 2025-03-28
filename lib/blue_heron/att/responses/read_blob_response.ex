# SPDX-FileCopyrightText: 2021 Troels Brødsgaard
# SPDX-FileCopyrightText: 2024 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.ATT.ReadBlobResponse do
  @moduledoc """
  > The ATT_READ_BLOB_RSP PDU is sent in reply to a received
  > ATT_READ_BLOB_REQ PDU and contains part of the value of the attribute that has
  > been read

  Bluetooth Spec v5.2, vol 3, Part F, 3.4.4.6
  """

  defstruct [:opcode, :value]

  def serialize(%{value: value}) do
    <<0x0D, value::binary>>
  end

  def deserialize(<<0x0D, value::binary>>) do
    %__MODULE__{opcode: 0x0D, value: value}
  end
end
