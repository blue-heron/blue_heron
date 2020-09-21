defmodule BlueHeron.HCI.Commands do
  # OpCode Group Fields
  @controller_and_baseband 0x03
  @informational_parameters 0x04
  @le_controller 0x08

  import BlueHeron.HCI.Helpers

  alias BlueHeron.HCI.Commands.SetEventMask
  alias BlueHeron.HCI.{Command, RawMessage, ReturnParameters}

  ##
  # Controller & Baseband Commands
  ##

  @doc """
  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.12
  """
  @spec encode(Command.t()) :: RawMessage.t()
  def encode(%Command{type: :read_local_name} = command) do
    %RawMessage{
      data: <<op(@controller_and_baseband, 0x0014)::little-16, 0, 0>>,
      decode_response: &decode_read_local_name_return_parameters/1,
      meta: command.meta
    }
  end

  def encode(%Command{type: :set_event_mask} = command) do
    events_mask = SetEventMask.mask_events(command.args)

    %RawMessage{
      data: <<op(@controller_and_baseband, 0x0001)::little-16, 8, events_mask::little-64>>,
      decode_response: &decode_set_event_mask_return_parameters/1,
      meta: command.meta
    }
  end

  def encode(%Command{type: :create_connection} = cc) do
    fields = <<
      cc.args.le_scan_interval::little-16,
      cc.args.le_scan_window::little-16,
      cc.args.initiator_filter_policy,
      cc.args.peer_address_type,
      cc.args.peer_address::little-48,
      cc.args.own_address_type,
      cc.args.connection_interval_min::little-16,
      cc.args.connection_interval_max::little-16,
      cc.args.connection_latency::little-16,
      cc.args.supervision_timeout::little-16,
      cc.args.min_ce_length::little-16,
      cc.args.max_ce_length::little-16
    >>

    fields_size = byte_size(fields)

    # no Return parameters
    %RawMessage{
      data: <<op(@le_controller, 0x000D)::little-16, fields_size, fields::binary>>,
      decode_response: fn _ -> {:ok, nil} end,
      meta: cc.meta
    }
  end

  # This is an example decoder. I don't think it's implemented unless we want
  # to make some sort of raw packet analysis library.
  @spec decode(RawMessage.t()) :: Command.t()
  def decode(%RawMessage{data: <<op(@controller_and_baseband, 0x0014)::little-16, 0, 0>>} = m) do
    %Command{type: :read_local_name, args: %{}, meta: m.meta}
  end

  def decode(
        %RawMessage{
          data: <<op(@controller_and_baseband, 0x0001)::little-16, 8, events::little-64>>
        } = p
      ) do
    SetEventMask.unmask_events(events)
    |> set_event_mask(p.meta)
  end

  def decode(
        %RawMessage{
          data:
            <<op(@le_controller, 0x000D)::little-16, fields_size,
              fields::binary-size(fields_size)>>
        } = packet
      ) do
    <<
      le_scan_interval::16-little,
      le_scan_window::16-little,
      initiator_filter_policy,
      peer_address_type,
      peer_address::little-48,
      own_address_type,
      connection_interval_min::16-little,
      connection_interval_max::16-little,
      connection_latency::16-little,
      supervision_timeout::16-little,
      min_ce_length::16-little,
      max_ce_length::16-little
    >> = fields

    args = %{
      le_scan_interval: le_scan_interval,
      le_scan_window: le_scan_window,
      initiator_filter_policy: initiator_filter_policy,
      peer_address_type: peer_address_type,
      peer_address: peer_address,
      own_address_type: own_address_type,
      connection_interval_min: connection_interval_min,
      connection_interval_max: connection_interval_max,
      connection_latency: connection_latency,
      supervision_timeout: supervision_timeout,
      min_ce_length: min_ce_length,
      max_ce_length: max_ce_length
    }

    create_connection(args, packet.meta)
  end

  defp decode_read_local_name_return_parameters(
         %RawMessage{
           data:
             <<op(@controller_and_baseband, 0x0014)::little-16, status::8, local_name::binary>>
         } = message
       ) do
    {:ok,
     %ReturnParameters{
       status: status,
       type: :read_local_name,
       args: %{local_name: trim_zero(local_name)},
       meta: message.meta
     }}
  end

  defp decode_set_event_mask_return_parameters(
         %RawMessage{data: <<op(@controller_and_baseband, 0x0001)::little-16, status>>} = packet
       ) do
    {:ok, %ReturnParameters{status: status, type: :set_event_mask, args: %{}, meta: packet.meta}}
  end

  @doc """
  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.1
  """
  @spec set_event_mask(keyword() | map()) :: any()
  def set_event_mask(events \\ SetEventMask.default(), meta \\ %{}) do
    %Command{type: :set_event_mask, args: events, meta: meta}
  end

  ##
  # Informational Parameters
  ##

  @doc """
  Bluetooth Spec v5.2, Vol 4, Part E, section 7.4.1
  """
  def read_local_version_information() do
    %{type: __MODULE__.ReadLocalVersionInformation}
  end

  ##
  # LE Controller
  ##

  @doc """
  Bluetooth Core Version 5.2 | Vol 4, Part E, section 7.8.12

  `:peer_address` option required
  """
  @connection_defaults %{
    le_scan_interval: 0x0C80,
    le_scan_window: 0x0640,
    initiator_filter_policy: 0,
    peer_address_type: 0,
    peer_address: nil,
    own_address_type: 0,
    connection_interval_min: 0x0024,
    connection_interval_max: 0x0C80,
    connection_latency: 0x0012,
    supervision_timeout: 0x0640,
    min_ce_length: 0x0006,
    max_ce_length: 0x0054
  }
  def create_connection(args \\ %{}, meta \\ %{}) do
    args = if Keyword.keyword?(args), do: Map.new(args), else: args

    %Command{type: :create_connection, args: Map.merge(@connection_defaults, args), meta: meta}
  end
end
