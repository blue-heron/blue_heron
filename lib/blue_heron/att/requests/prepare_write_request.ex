# SPDX-FileCopyrightText: 2021 Troels Brødsgaard
# SPDX-FileCopyrightText: 2024 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.ATT.PrepareWriteRequest do
  @moduledoc """
  > The ATT_PREPARE_WRITE_REQ PDU is used to request the server to prepare
  > to write the value of an attribute.

  Bluetooth Spec v5.2, vol 3, Part F, 3.4.6.1
  """

  defstruct [:opcode, :handle, :offset, :value]

  def serialize(%{handle: handle, offset: offset, value: value}) do
    <<0x16, handle::little-16, offset::little-16, value::binary>>
  end

  def deserialize(<<0x16, handle::little-16, offset::little-16, value::binary>>) do
    %__MODULE__{opcode: 0x16, handle: handle, offset: offset, value: value}
  end
end
