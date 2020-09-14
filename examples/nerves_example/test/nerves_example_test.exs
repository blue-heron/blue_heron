defmodule NervesExampleTest do
  use ExUnit.Case
  doctest NervesExample

  test "greets the world" do
    assert NervesExample.hello() == :world
  end
end
