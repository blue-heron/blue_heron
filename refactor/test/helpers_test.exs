defmodule HelpersTest do
  use ExUnit.Case
  import BlueHeron.HCI.Helpers

  test "op/2" do
    assert 3092 == op(0x03, 0x0014)
  end

  test "trim_zero/1" do
    assert "asdf" == trim_zero("asdf" <> :binary.copy(<<0>>, 50))
    assert "asdf" == trim_zero(<<"asdf", 0, "jkl", 0>>)
    assert "asdf" == trim_zero("asdf")
    assert "" == trim_zero(<<0, 0>>)
    assert "" == trim_zero("")
  end
end
