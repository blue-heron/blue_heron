defmodule BlueHeron.HCIDump.PKTLOG do
  @moduledoc "HCIDump Packet structure"
  defstruct tv_sec: 0,
            tv_us: 0,
            type: :LOG_MESSAGE_PACKET,
            payload: nil
end
