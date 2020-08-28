defmodule BlueHeronExampleGoveeTest do
  use ExUnit.Case
  doctest BlueHeronExampleGovee

  test "greets the world" do
    assert BlueHeronExampleGovee.hello() == :world
  end
end
