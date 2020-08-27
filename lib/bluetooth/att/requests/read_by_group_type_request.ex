defmodule Bluetooth.ATT.ReadByGroupTypeRequest do
  defstruct [:opcode, :starting_handle, :ending_handle, :uuid]

  def serialize(%{
        starting_handle: starting_handle,
        ending_handle: ending_handle,
        uuid: uuid
      })
      when uuid > 65535 do
    <<0x10::8, starting_handle::little-16, ending_handle::little-16, uuid::little-128>>
  end

  def serialize(%{
        starting_handle: starting_handle,
        ending_handle: ending_handle,
        uuid: uuid
      }) do
    <<0x10::8, starting_handle::little-16, ending_handle::little-16, uuid::little-16>>
  end

  def deserialize(
        <<0x10::8, starting_handle::little-16, ending_handle::little-16, uuid::little-16>>
      ) do
    %__MODULE__{
      opcode: 0x10,
      starting_handle: starting_handle,
      ending_handle: ending_handle,
      uuid: uuid
    }
  end

  def deserialize(
        <<0x10::8, starting_handle::little-16, ending_handle::little-16, uuid::little-128>>
      ) do
    %__MODULE__{
      opcode: 0x10,
      starting_handle: starting_handle,
      ending_handle: ending_handle,
      uuid: uuid
    }
  end
end
