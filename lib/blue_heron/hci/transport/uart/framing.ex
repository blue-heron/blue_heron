# SPDX-FileCopyrightText: 2024 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Transport.UART.Framing do
  @moduledoc """
  A framer module that defines a frame as a HCI packet.

  Reference: Version 5.0, Vol 2, Part E, 5.4
  """

  alias Circuits.UART.Framing

  defmodule State do
    @moduledoc false

    defstruct frame: <<>>, type: nil, frames: []
  end

  # Max bytes to buffer without producing a frame before resetting.
  # BLE ACL max is ~521 bytes, HCI events max 258 bytes. 1024 is generous.
  @max_buffer_size 1024

  @behaviour Framing

  @impl Framing
  def init(_args), do: {:ok, %State{}}

  @impl Framing
  def add_framing(data, state), do: {:ok, data, state}

  @impl Framing
  def flush(:transmit, state), do: state

  def flush(:receive, _state), do: %State{}

  def flush(:both, _state), do: %State{}

  @impl Framing
  def frame_timeout(state) do
    # Discard partial frame and reset — we've waited long enough for remaining bytes
    if byte_size(state.frame) > 0 do
      :logger.warning(%{
        msg: "framing: timeout, discarding partial frame",
        type: state.type,
        discarded: byte_size(state.frame)
      })
    end

    {:ok, Enum.reverse(state.frames), %State{}}
  end

  @impl Framing
  def remove_framing(new_data, state) do
    combined = state.frame <> new_data

    # If we've accumulated too much data without producing a frame,
    # sync is lost (bytes were dropped by the UART). Scan for the next
    # valid HCI packet type byte and resume from there.
    {combined, state} =
      if byte_size(combined) > @max_buffer_size do
        :logger.warning(%{
          msg: "framing: buffer overflow, scanning for sync",
          buffered: byte_size(combined),
          type: state.type
        })

        {scan_for_sync(combined), %{state | type: nil}}
      else
        {combined, state}
      end

    process(combined, %{state | frame: <<>>})
  end

  # --- Packet type detection (type = nil) ---

  def process(<<0x2, rest::binary>>, %{type: nil} = state) do
    process(rest, %{state | type: 0x2})
  end

  def process(<<0x4, rest::binary>>, %{type: nil} = state) do
    process(rest, %{state | type: 0x4})
  end

  # Skip invalid bytes when looking for a packet type.
  # After sync loss (e.g. dropped UART bytes), we may see leftover data
  # bytes that aren't valid HCI packet type indicators.
  def process(<<_byte, rest::binary>>, %{type: nil} = state) do
    process(rest, state)
  end

  # --- ACL data packet (type = 0x2) ---

  def process(
        <<handle_and_flags::binary-size(2), length::little-16, data::binary-size(length),
          rest::binary>>,
        %{type: 0x2} = state
      ) do
    frame = <<0x2, handle_and_flags::binary, length::little-16, data::binary-size(length)>>
    process(rest, %{state | type: nil, frames: [frame | state.frames]})
  end

  # --- HCI event packet (type = 0x4) ---

  def process(
        <<event_code::size(8), parameter_total_length::size(8),
          event_parameters::binary-size(parameter_total_length), rest::binary>>,
        %{type: 0x4} = state
      ) do
    frame =
      <<0x4, event_code::size(8), parameter_total_length::size(8),
        event_parameters::binary-size(parameter_total_length)>>

    process(rest, %{state | type: nil, frames: [frame | state.frames]})
  end

  # --- End of data ---

  def process(<<>>, %{type: nil} = state) do
    {:ok, Enum.reverse(state.frames), %{state | frames: []}}
  end

  # --- Partial frame: need more data ---

  def process(data, state) do
    {:ok, Enum.reverse(state.frames), %{state | frame: data, frames: []}}
  end

  # Scan forward through data looking for the next valid HCI packet type byte.
  # This is a best-effort recovery — 0x02/0x04 could appear in payload data,
  # but the framing will self-correct on the next valid packet boundary.
  defp scan_for_sync(<<0x2, _::binary>> = data), do: data
  defp scan_for_sync(<<0x4, _::binary>> = data), do: data
  defp scan_for_sync(<<_, rest::binary>>), do: scan_for_sync(rest)
  defp scan_for_sync(<<>>), do: <<>>
end
