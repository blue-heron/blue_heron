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
  def frame_timeout(state), do: {:ok, [state], <<>>}

  @impl Framing
  def remove_framing(new_data, state) do
    process(state.frame <> new_data, %{state | frame: <<>>})
  end

  def process(<<0x2, rest::binary>>, %{type: nil} = state) do
    process(rest, %{state | type: 0x2})
  end

  def process(<<0x4, rest::binary>>, %{type: nil} = state) do
    process(rest, %{state | type: 0x4})
  end

  def process(
        <<handle::little-12, flags::4, length::little-16, data::binary-size(length),
          rest::binary>>,
        %{type: 0x2} = state
      ) do
    frame = <<0x2, handle::little-12, flags::4, length::little-16, data::binary-size(length)>>
    process(rest, %{state | type: nil, frames: [frame | state.frames]})
  end

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

  def process(<<>>, state) do
    {:ok, Enum.reverse(state.frames), %{state | frames: []}}
  end

  def process(data, state), do: {:in_frame, [], %{state | frame: data}}
end
