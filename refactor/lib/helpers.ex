defmodule BlueHeron.HCI.Helpers do
  alias BlueHeron.ErrorCode

  @moduledoc false
  def as_uint8(val) when val in [1, "1", true, <<1>>], do: 1
  def as_uint8(_val), do: 0

  def decode_status!(status) do
    %{
      status: status,
      status_name: ErrorCode.name!(status)
    }
  end
end
