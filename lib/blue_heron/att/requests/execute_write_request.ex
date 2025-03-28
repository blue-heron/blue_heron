# SPDX-FileCopyrightText: 2021 Troels Brødsgaard
# SPDX-FileCopyrightText: 2024 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.ATT.ExecuteWriteRequest do
  @moduledoc """
  > The ATT_EXECUTE_WRITE_REQ PDU is used to request the server to write or cancel
  > the write of all the prepared values currently held in the prepare queue from this client.
  > This request shall be handled by the server as an atomic operation

  Bluetooth Spec v5.2, vol 3, Part F, 3.4.6.3
  """

  defstruct [:opcode, :flags]

  def serialize(%{flags: flags}) do
    <<0x18, flags>>
  end

  def deserialize(<<0x18, flags>>) do
    %__MODULE__{opcode: 0x18, flags: flags}
  end
end
