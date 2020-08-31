defmodule BlueHeron.HCI.Commands do
  @type ogf :: 1..64
  @type ocf :: 1..1024

  @type command_map :: %{
          required(:type) => atom(),
          required(:ocf) => ocf(),
          optional(atom()) => any()
        }

  # OpCode Group Fields
  @controller_and_baseband 0x03
  @informational_parameters 0x04
  @le_controller 0x08

  alias BlueHeron.HCI.Commands.SetEventMask

  import BlueHeron.HCI.Helpers

  @doc """
  Helper to create Command opcode from OCF and OGF values
  """
  @spec op(ogf(), ocf()) :: non_neg_integer()
  defmacro op(ogf, ocf) do
    ogf = Macro.expand(ogf, __CALLER__)
    ocf = Macro.expand(ocf, __CALLER__)
    <<opcode::16>> = <<ogf::6, ocf::10>>
    opcode
  end

  @spec decode(binary()) :: command_map()
  def decode(command_map)

  @spec encode(command_map()) :: binary()
  def encode(command_map)

  ##
  # Controller & Baseband Commands
  ##

  @doc """
  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.12
  """
  @spec read_local_name() :: command_map()
  def read_local_name() do
    %{type: __MODULE__.ResetLocalName, ocf: 0x0014}
  end

  def encode(%{type: __MODULE__.ResetLocalName}) do
    <<op(@controller_and_baseband, 0x0014)::little-16, 0, 0>>
  end

  def encode_return_parameters(%{opcode: op(@controller_and_baseband, 0x0014)} = rp) do
    rem = 248 - byte_size(rp.local_name)
    <<rp.opcode::little-16, rp.status::8, rp.local_name::binary, 0::rem*8>>
  end

  def decode(<<op(@controller_and_baseband, 0x0014)::little-16, 0, 0>>) do
    read_local_name()
  end

  def decode_return_parameters(
        <<op(@controller_and_baseband, 0x0014)::little-16, status::8, local_name::binary>>
      ) do
    # The local name field will fill any remainder of the
    # 248 bytes with null bytes. So just trim those.
    decode_status!(status)
    |> Map.put(:local_name, String.trim(local_name, <<0>>))
  end

  # @doc """
  # Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.2
  # """
  # def reset() do
  #   opcode(@controller_and_baseband, 0x0003) <> <<0::8, 0>>
  # end

  @doc """
  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.1
  """
  @spec set_event_mask(keyword() | map()) :: command_map()
  def set_event_mask(events \\ SetEventMask.default()) do
    %{events: events, type: __MODULE__.SetEventMask, ocf: 0x0001}
  end

  def encode(%{events: events, type: __MODULE__.SetEventMask}) do
    event_mask = SetEventMask.mask_events(events)
    mask_size = byte_size(event_mask)
    <<op(@controller_and_baseband, 0x0001)::little-16, mask_size::8, event_mask::binary>>
  end

  def decode(
        <<op(@controller_and_baseband, 0x0001)::little-16, esize, event_mask::binary-size(esize)>>
      ) do
    set_event_mask(SetEventMask.unmask_events(event_mask))
  end

  # @doc """
  # Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.26
  # """
  # @spec write_class_of_device(non_neg_integer()) :: binary()
  # def write_class_of_device(class) do
  #   opcode(@controller_and_baseband, 0x0024) <> <<3::8, class::24>>
  # end

  # @doc """
  # Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.56
  # """
  # def write_extended_query_response(response \\ <<0>>, fec_required? \\ false) do
  #   rem = 240 - byte_size(response)

  #   <<
  #     opcode(@controller_and_baseband, 0x0052)::binary,
  #     241::8,
  #     as_uint8(fec_required?)::8,
  #     response::binary,
  #     0::rem*8
  #   >>
  # end

  # @doc """
  # Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.50
  # """
  # def write_inquiry_mode(inquiry_mode \\ 0) when inquiry_mode <= 2 do
  #   opcode(@controller_and_baseband, 0x0045) <> <<1::8, inquiry_mode::8>>
  # end

  # @doc """
  # Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.11
  # """
  # def write_local_name(name) when is_binary(name) do
  #   rem = 248 - byte_size(name)
  #   opcode(@controller_and_baseband, 0x0013) <> <<248::8, name::binary, 0::rem*8>>
  # end

  # @doc """
  # Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.16
  # """
  # def write_page_timeout(timeout \\ 0x20) when is_integer(timeout) do
  #   opcode(@controller_and_baseband, 0x0018) <> <<2::8, timeout::16>>
  # end

  # @doc """
  # Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.92
  # """
  # def write_secure_connections_host_support(enabled? \\ false) do
  #   opcode(@controller_and_baseband, 0x007A) <> <<1::8, as_uint8(enabled?)::8>>
  # end

  # @doc """
  # Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.59
  # """
  # def write_simple_pairing_mode(enabled? \\ false) do
  #   opcode(@controller_and_baseband, 0x0056) <> <<1::8, as_uint8(enabled?)::8>>
  # end

  ##
  # Informational Parameters
  ##

  @doc """
  Bluetooth Spec v5.2, Vol 4, Part E, section 7.4.1
  """
  def read_local_version_information() do
    %{type: __MODULE__.ReadLocalVersionInformation}
  end

  def encode(%{type: __MODULE__.ReadLocalVersionInformation}) do
    <<op(@informational_parameters, 0x0001)::little-16, 0, 0>>
  end

  def decode(<<op(@informational_parameters, 0x0001)::little-16, 0, 0>>) do
    read_local_version_information()
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
  def create_connection(args \\ %{}) do
    args = if Keyword.keyword?(args), do: Map.new(args), else: args

    Map.merge(@connection_defaults, args)
    |> Map.put(:type, __MODULE__.CreateConnection)
  end

  def encode(%{type: __MODULE__.CreateConnection} = cmd) do
    fields = <<
      cmd.le_scan_interval::16-little,
      cmd.le_scan_window::16-little,
      cmd.initiator_filter_policy::8,
      cmd.peer_address_type::8,
      cmd.peer_address::little-48,
      cmd.own_address_type::8,
      cmd.connection_interval_min::16-little,
      cmd.connection_interval_max::16-little,
      cmd.connection_latency::16-little,
      cmd.supervision_timeout::16-little,
      cmd.min_ce_length::16-little,
      cmd.max_ce_length::16-little
    >>

    fields_size = byte_size(fields)
    <<op(@le_controller, 0x000D)::little-16, fields_size::8, fields::binary>>
  end

  def decode(
        <<op(@le_controller, 0x000D)::little-16, _size, le_scan_interval::16-little,
          le_scan_window::16-little, initiator_filter_policy::8, peer_address_type::8,
          peer_address::little-48, own_address_type::8, connection_interval_min::16-little,
          connection_interval_max::16-little, connection_latency::16-little,
          supervision_timeout::16-little, min_ce_length::16-little, max_ce_length::16-little>>
      ) do
    create_connection(%{
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
    })
  end
end
