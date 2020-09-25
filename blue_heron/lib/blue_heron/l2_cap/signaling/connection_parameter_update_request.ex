defmodule BlueHeron.L2Cap.Signaling.ConnectionParameterUpdateRequest do
  defstruct code: 0x12,
            identifier: nil,
            interval_min: 0x0,
            interval_max: 0x0,
            slave_latency: 0x0,
            timeout_multiplier: 0x0

  def deserialize(<<0x12, identifier, length::little-16, data::binary-size(length)>>) do
    <<interval_min::little-16, interval_max::little-16, slave_latency::little-16,
      timeout_multiplier::little-16>> = data

    %__MODULE__{
      identifier: identifier,
      interval_min: interval_min,
      interval_max: interval_max,
      slave_latency: slave_latency,
      timeout_multiplier: timeout_multiplier
    }
  end

  def serialize(%__MODULE__{
        identifier: identifier,
        interval_min: interval_min,
        interval_max: interval_max,
        slave_latency: slave_latency,
        timeout_multiplier: timeout_multiplier
      }) do
    data = <<
      interval_min::little-16,
      interval_max::little-16,
      slave_latency::little-16,
      timeout_multiplier::little-16
    >>

    length = byte_size(data)
    <<0x12, identifier, length::little-16, data::binary-size(length)>>
  end
end
