# SPDX-FileCopyrightText: 2021 Troels Brødsgaard
# SPDX-FileCopyrightText: 2024 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.ATT.ExecuteWriteResponse do
  @moduledoc """
  > The ATT_EXECUTE_WRITE_RSP PDU is sent in response to a received
  > ATT_EXECUTE_WRITE_REQ PDU.

  Bluetooth Spec v5.2, vol 3, Part F, 3.4.6.4
  """

  defstruct [:opcode]

  def serialize(%{}) do
    <<0x19>>
  end

  def deserialize(<<0x19>>) do
    %__MODULE__{opcode: 0x19}
  end
end
