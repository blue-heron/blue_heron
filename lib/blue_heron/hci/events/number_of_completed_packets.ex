# SPDX-FileCopyrightText: 2023 Markus Hutzler
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Event.NumberOfCompletedPackets do
  use BlueHeron.HCI.Event, code: 0x13

  @moduledoc """
  > The HCI_Number_Of_Completed_Packets event is used by the Controller to
  > indicate to the Host how many HCI Data packets have been completed for
  > each Connection_Handle since the previous HCI_Number_Of_Completed_-
  > Packets event was sent to the Host.

  Reference: Version 5.3, Vol 4, Part E, 7.7.19
  """

  require Logger

  defparameters [:num_handles, :data]

  defimpl BlueHeron.HCI.Serializable do
    def serialize(data) do
      bin = <<data.num_handles, data.data::binary>>
      size = byte_size(bin)
      <<data.code, size, bin::binary>>
    end
  end

  @impl BlueHeron.HCI.Event
  def deserialize(<<@code, _size, num_handles, data::binary>>) do
    # TODO: deserialize data
    %__MODULE__{
      num_handles: num_handles,
      data: data
    }
  end

  def deserialize(bin), do: {:error, bin}
end
