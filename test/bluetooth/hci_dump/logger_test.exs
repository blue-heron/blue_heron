defmodule Bluetooth.HCIDump.LoggerTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  require Bluetooth.HCIDump.Logger

  test "encodes PKTLogger packets" do
    uniq = System.unique_integer()
    test_str = "test string #{uniq}"

    # remove the log file for good luck
    File.rm(Bluetooth.HCIDump.Logger.logfile())

    # add the backend
    Logger.add_backend(Bluetooth.HCIDump.Logger)

    # send the log
    assert capture_log(fn ->
             Bluetooth.HCIDump.Logger.info(test_str)
           end) =~ test_str

    decoded = Bluetooth.HCIDump.decode_file!(Bluetooth.HCIDump.Logger.logfile())

    assert Enum.find(decoded, fn
             %{payload: payload, type: type} ->
               String.contains?(payload, test_str) && type == :LOG_MESSAGE_PACKET
           end)
  end
end
