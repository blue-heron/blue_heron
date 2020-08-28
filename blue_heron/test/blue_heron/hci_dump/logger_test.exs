defmodule BlueHeron.HCIDump.LoggerTest do
  use ExUnit.Case
  import ExUnit.CaptureLog
  require BlueHeron.HCIDump.Logger

  test "encodes PKTLogger packets" do
    uniq = System.unique_integer([:positive])
    test_str = "test string #{uniq}"
    logfile = Path.join([System.tmp_dir!(), "hcidump-#{uniq}.pkgl"])
    _ = Logger.remove_backend(BlueHeron.HCIDump.Logger)

    # remove the log file for good luck
    File.rm(logfile)

    # add the backend
    {:ok, _} = Logger.add_backend(BlueHeron.HCIDump.Logger, flush: true)
    Logger.configure_backend(BlueHeron.HCIDump.Logger, logfile: logfile)

    # send the log
    assert capture_log(fn ->
             BlueHeron.HCIDump.Logger.info(test_str)
           end) =~ test_str

    decoded = BlueHeron.HCIDump.decode_file!(logfile)

    assert Enum.find(decoded, fn
             %{payload: payload, type: type} ->
               String.contains?(payload, test_str) && type == :LOG_MESSAGE_PACKET
           end)
  end
end
