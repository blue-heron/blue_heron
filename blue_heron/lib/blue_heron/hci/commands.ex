defmodule BlueHeron.HCI.Commands do
  @type group ::
          :controller_and_baseband
          | :le_controller
          | :link_control
          | :link_policy
          | :informational_parameters
          | :status_parameters
          | :testing

  @opcode_group_fields %{
    controller_and_baseband: 0x03
  }

  @doc """
  Helper to create Command opcode from OCF and OGF values
  """
  @spec opcode(group() | non_neg_integer(), non_neg_integer()) :: binary()
  def opcode(group, ocf) when is_atom(group) do
    ogf = Map.fetch!(@opcode_group_fields, group)
    opcode(ogf, ocf)
  end

  def opcode(ogf, ocf) when ogf < 64 and ocf < 1024 do
    <<opcode::16>> = <<ogf::6, ocf::10>>
    <<opcode::little-16>>
  end

  ##
  # Controller & Baseband Commands
  ##

  @doc """
  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.12
  """
  def read_local_name() do
    opcode(:controller_and_baseband, 0x0014) <> <<0::8, "">>
  end

  @doc """
  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.2
  """
  def reset() do
    opcode(:controller_and_baseband, 0x0003) <> <<0::8, "">>
  end

  @doc """
  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.1
  """
  def set_event_mask(event_mask \\ <<0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF>>) do
    mask_size = byte_size(event_mask)
    opcode(:controller_and_baseband, 0x0001) <> <<mask_size::8, event_mask::binary>>
  end

  @doc """
  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.26
  """
  def write_class_of_device(class) do
    opcode(:controller_and_baseband, 0x00) <> <<3::8, class::24>>
  end

  @doc """
  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.56
  """
  def write_extended_query_response(response \\ <<0>>, fec_required? \\ false) do
    rem = 240 - byte_size(response)

    <<
      opcode(:controller_and_baseband, 0x0052)::binary,
      241::8,
      as_uint8(fec_required?)::8,
      response::binary,
      0::rem*8
    >>
  end

  @doc """
  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.50
  """
  def write_inquiry_mode(inquiry_mode \\ 0) when inquiry_mode <= 2 do
    opcode(:controller_and_baseband, 0x0045) <> <<1::8, inquiry_mode::8>>
  end

  @doc """
  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.11
  """
  def write_local_name(name) when is_binary(name) do
    rem = 248 - byte_size(name)
    opcode(:controller_and_baseband, 0x0013) <> <<248::8, name::binary, 0::rem*8>>
  end

  @doc """
  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.16
  """
  def write_page_timeout(timeout \\ 0x20) when is_integer(timeout) do
    opcode(:controller_and_baseband, 0x0018) <> <<2::8, timeout::16>>
  end

  @doc """
  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.92
  """
  def write_secure_connections_host_support(enabled? \\ false) do
    opcode(:controller_and_baseband, 0x007A) <> <<1::8, as_uint8(enabled?)::8>>
  end

  @doc """
  Bluetooth Spec v5.2, Vol 4, Part E, section 7.3.59
  """
  def write_simple_pairing_mode(enabled? \\ false) do
    opcode(:controller_and_baseband, 0x0056) <> <<1::8, as_uint8(enabled?)::8>>
  end

  defp as_uint8(val) when val in [1, "1", true, <<1>>], do: 1
  defp as_uint8(_val), do: 0
end
