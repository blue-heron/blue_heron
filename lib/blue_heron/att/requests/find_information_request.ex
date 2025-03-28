# SPDX-FileCopyrightText: 2021 Troels Brødsgaard
# SPDX-FileCopyrightText: 2024 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.ATT.FindInformationRequest do
  @moduledoc """
  > The ATT_FIND_INFORMATION_REQ PDU is used to obtain the mapping of attribute
  > handles with their associated types. This allows a client to discover the list of attributes
  > and their types on a server.

  Bluetooth Spec v5.2, vol 3, Part F, 3.4.3.1
  """

  defstruct [:opcode, :starting_handle, :ending_handle]

  def serialize(%{starting_handle: starting_handle, ending_handle: ending_handle}) do
    <<0x04, starting_handle::little-16, ending_handle::little-16>>
  end

  def deserialize(<<0x04, starting_handle::little-16, ending_handle::little-16>>) do
    %__MODULE__{opcode: 0x04, starting_handle: starting_handle, ending_handle: ending_handle}
  end
end
