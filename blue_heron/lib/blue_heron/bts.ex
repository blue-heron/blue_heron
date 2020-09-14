defmodule BlueHeron.BTS do
  @moduledoc """
  Decoder for the special format that TI uses for their bluetooth modules
  """

  @magic 0x42535442
  # pretty sure `@version` is a special attr in beam
  @expected_version 1

  defmodule Action do
    defstruct [:type, :data]
  end

  defstruct magic: @magic, version: @expected_version, future: 0, actions: []

  def decode_file!(path) do
    path
    |> File.read!()
    |> decode()
  end

  def decode(
        <<@magic::native-32, @expected_version::native-32, _future::binary-size(24),
          actions::binary>>
      ) do
    actions = decode_actions(actions, [])
    %__MODULE__{actions: actions}
  end

  def decode(<<magic::native-32, version::native-32, _future::binary-size(24), _actions::binary>>) do
    raise "Unknown magic or version: #{inspect(magic, base: :hex)}, #{version}"
  end

  def decode_actions(
        <<type::little-16, length::little-16, action::binary-size(length), actions::binary>>,
        acc
      ) do
    decode_actions(actions, [decode_action(type, action) | acc])
  end

  def decode_actions(<<>>, acc), do: Enum.reverse(acc)

  @hci_command_packet 0x1
  @action_send_command 1
  @action_wait_event 2
  @action_serial 3
  @action_delay 4
  @action_run_script 5
  @action_remarks 6

  def decode_action(@action_send_command, data),
    do: %Action{type: :action_send_command, data: data}

  def decode_action(
        @action_wait_event,
        <<msec::little-32, length::little-32, wait_data::binary-size(length)>>
      ),
      do: %Action{type: :action_wait_event, data: %{msec: msec, wait_data: wait_data}}

  def decode_action(@action_serial, <<baud::little-32, flow::little-32>>),
    do: %Action{type: :action_serial, data: %{baud: baud, flow: flow}}

  def decode_action(@action_delay, <<msec::little-32>>),
    do: %Action{type: :action_delay, data: msec}

  def decode_action(@action_run_script, data),
    do: %Action{type: :action_run_script, data: data}

  def decode_action(@action_remarks, data),
    do: %Action{type: :action_remarks, data: String.trim(data, <<0x0>>)}
end
