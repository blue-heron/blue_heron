# SPDX-FileCopyrightText: 2021 Troels Brødsgaard
# SPDX-FileCopyrightText: 2024 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.ATT.WriteResponse do
  @moduledoc """
  > The ATT_WRITE_RSP PDU is sent in reply to a valid ATT_WRITE_REQ PDU and
  > acknowledges that the attribute has been successfully written.

  Bluetooth Spec v5.2, vol 3, Part F, 3.4.5.2
  """

  defstruct [:opcode]

  def serialize(%{}) do
    <<0x13>>
  end

  def deserialize(<<0x13>>) do
    %__MODULE__{opcode: 0x13}
  end
end
