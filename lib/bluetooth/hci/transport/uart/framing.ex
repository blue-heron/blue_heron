defmodule Bluetooth.HCI.Transport.UART.Framing do
  @moduledoc """
  A framer module that defines a frame as a HCI packet.

  Reference: Version 5.0, Vol 2, Part E, 5.4
  """

  alias Circuits.UART.Framing

  defmodule State do
    @moduledoc false

    defstruct frame: <<>>, remaining_bytes: nil
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
  def remove_framing(new_data, state), do: process_data(new_data, state)

  @doc """
  Returns a tuple like `{remaining_desired_length, part_of_bin, rest_of_bin}`.

      iex> binary_split(<<1, 2, 3, 4>>, 0)
      {0, <<>>, <<1, 2, 3, 4>>}

      iex> binary_split(<<1, 2, 3, 4>>, 2)
      {0, <<1, 2>>, <<3, 4>>}

      iex> binary_split(<<1, 2, 3, 4>>, 4)
      {0, <<1, 2, 3, 4>>, <<>>}

      iex> binary_split(<<1, 2, 3, 4>>, 6)
      {2, <<1, 2, 3, 4>>, <<>>}
  """
  def binary_split(bin, desired_length) do
    bin_length = byte_size(bin)

    if bin_length < desired_length do
      {desired_length - bin_length, bin, <<>>}
    else
      {0, binary_part(bin, 0, desired_length),
       binary_part(bin, bin_length, desired_length - bin_length)}
    end
  end

  # `process_data/3` attempts to determine the type and length of a packet and will be called as
  # data is received
  defp process_data(data, state, messages \\ [])

  # recursion base case
  defp process_data(<<>>, state, messages) do
    {process_status(state), Enum.reverse(messages), state}
  end

  # HCI ACL Data Packet
  defp process_data(
         <<2, _::size(16), length::size(16)>> <> data,
         %State{frame: <<>>} = state,
         messages
       ) do
    process_data(data, length, state, messages)
  end

  # HCI Synchronous Data Packet
  defp process_data(
         <<3, _::size(16), length::size(8)>> <> data,
         %State{frame: <<>>} = state,
         messages
       ) do
    process_data(data, length, state, messages)
  end

  # HCI Event Packet
  defp process_data(
         <<4, event_code::size(8), parameter_total_length::size(8), event_parameters::bits>>,
         %State{frame: <<>>} = state,
         messages
       ) do
    process_data(
      event_parameters,
      parameter_total_length,
      %{state | frame: <<4, event_code, parameter_total_length>>},
      messages
    )
  end

  # bad packet type
  defp process_data(
         <<indicator, _::bits>> = data,
         %State{frame: <<>>} = state,
         messages
       )
       when indicator not in 2..4 do
    process_data(<<>>, state, [{:error, {:bad_packet_type, data}} | messages])
  end

  # pull data off the binary - already in a packet, however that does not mean the packet type and
  # length have been resolved yet
  defp process_data(data, state, messages) do
    process_data(data, state.remaining_bytes, state, messages)
  end

  # `process_data/4` appends data to the frame until it has satisfied the remaining bytes
  defp process_data(data, remaining_bytes, state, messages)

  # no data, we don't know how many bytes we want yet
  defp process_data(<<>> = data, nil, state, messages) do
    process_data(data, state, messages)
  end

  # there is data, we don't know how many bytes we want yet, and the frame is empty, move the data
  # in-frame
  defp process_data(data, nil, %State{frame: <<>>} = state, messages) do
    process_data(<<>>, %{state | frame: data}, messages)
  end

  # there is data, we don't know how many bytes we want yet, and the frame is not empty, append
  # the data to the frame
  defp process_data(data, nil, state, messages) do
    process_data(state.frame <> data, %{state | frame: <<>>}, messages)
  end

  # there is data, we know how many bytes we want, append to the frame
  defp process_data(data, remaining_bytes, state, messages) do
    case binary_split(data, remaining_bytes) do
      # the current remaining_bytes has been satisfied
      {0, message, remaining_data} ->
        process_data(remaining_data, %State{}, [state.frame <> message | messages])

      # the current remaining_bytes has not been satisfied
      {remaining_bytes, frame, <<>> = remaining_data} ->
        process_data(
          remaining_data,
          %{state | remaining_bytes: remaining_bytes, frame: state.frame <> frame},
          messages
        )
    end
  end

  defp process_status(%State{frame: <<>>, remaining_bytes: nil}), do: :ok

  defp process_status(_state), do: :in_frame
end
