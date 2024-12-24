defmodule BlueHeron.AdvertisingData.IBeacon do
  @moduledoc """
  Handles creating Apple IBeacon packets
  """

  # Apple's ID
  @company_id <<0x4C, 0x00>>
  # iBeacon type
  @ibeacon_type <<0x02>>
  # Length of the payload (21 bytes)
  @payload_length <<21>>

  @doc """
  Create a IBeacon packet.

  * UUID - 128 bit binary
  * major and minor - a 16 bit identifier
  * tx power - calibrated signal strength measured 1 meter away from the device. Helps estimate proximity.
  """
  @spec new(binary(), 0..65535, 0..65535, -128..127) :: binary()
  def new(uuid, major, minor, tx_power) do
    payload = <<major::16, minor::16, tx_power::signed-8>>
    @company_id <> @ibeacon_type <> @payload_length <> uuid <> payload
  end
end
