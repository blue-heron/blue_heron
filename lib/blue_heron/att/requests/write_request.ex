# SPDX-FileCopyrightText: 2021 Troels Brødsgaard
# SPDX-FileCopyrightText: 2024 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.ATT.WriteRequest do
  @moduledoc """
  > The ATT_WRITE_REQ PDU is used to request the server to write the value of an
  > attribute and acknowledge that this has been achieved in an ATT_WRITE_RSP PDU.

  Bluetooth Spec v5.2, vol 3, Part F, 3.4.5.1
  """

  defstruct [:opcode, :handle, :value]

  def serialize(%{handle: handle, value: value}) do
    <<0x12, handle::little-16, value::binary>>
  end

  def deserialize(<<0x12, handle::little-16, value::binary>>) do
    %__MODULE__{opcode: 0x12, handle: handle, value: value}
  end
end
