# SPDX-FileCopyrightText: 2020 Connor Rigby
# SPDX-FileCopyrightText: 2020 Frank Hunleth
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.ATT.ReadByGroupTypeRequest do
  @moduledoc """
  > The ATT_READ_BY_GROUP_TYPE_REQ PDU is used to obtain the values of
  > attributes where the attribute type is known, the type of a grouping attribute as defined
  > by a higher layer specification, but the handle is not known.

  Bluetooth Spec v5.2, vol 3, Part F, 3.4.4.9
  """

  defstruct [:opcode, :starting_handle, :ending_handle, :uuid]

  def serialize(%{
        starting_handle: starting_handle,
        ending_handle: ending_handle,
        uuid: uuid
      })
      when uuid > 65535 do
    <<0x10, starting_handle::little-16, ending_handle::little-16, uuid::little-128>>
  end

  def serialize(%{
        starting_handle: starting_handle,
        ending_handle: ending_handle,
        uuid: uuid
      }) do
    <<0x10, starting_handle::little-16, ending_handle::little-16, uuid::little-16>>
  end

  def deserialize(<<0x10, starting_handle::little-16, ending_handle::little-16, uuid::little-16>>) do
    %__MODULE__{
      opcode: 0x10,
      starting_handle: starting_handle,
      ending_handle: ending_handle,
      uuid: uuid
    }
  end

  def deserialize(
        <<0x10, starting_handle::little-16, ending_handle::little-16, uuid::little-128>>
      ) do
    %__MODULE__{
      opcode: 0x10,
      starting_handle: starting_handle,
      ending_handle: ending_handle,
      uuid: uuid
    }
  end
end
