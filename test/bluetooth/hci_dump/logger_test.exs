defmodule Bluetooth.HCIDump.LoggerTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  require Bluetooth.HCIDump.Logger

  test "encodes PKTLogger packets" do
    uniq = System.unique_integer([:positive])
    test_str = "test string #{uniq}"
    logfile = Path.join([System.tmp_dir!(), "hcidump-#{uniq}.pkgl"])
    _ = Logger.remove_backend(Bluetooth.HCIDump.Logger)

    # remove the log file for good luck
    File.rm(logfile)

    # add the backend
    {:ok, _} = Logger.add_backend(Bluetooth.HCIDump.Logger, flush: true)
    Logger.configure_backend(Bluetooth.HCIDump.Logger, logfile: logfile)

    # send the log
    assert capture_log(fn ->
             Bluetooth.HCIDump.Logger.info(test_str)
           end) =~ test_str

    decoded = Bluetooth.HCIDump.decode_file!(logfile)

    assert Enum.find(decoded, fn
             %{payload: payload, type: type} ->
               String.contains?(payload, test_str) && type == :LOG_MESSAGE_PACKET
           end)
  end
end
