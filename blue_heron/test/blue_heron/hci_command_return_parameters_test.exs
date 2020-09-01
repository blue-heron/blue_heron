defmodule BlueHeron.HCI.Commands.ReturnParametersTest do
  use ExUnit.Case, async: true

  alias BlueHeron.HCI.Commands.ReturnParameters

  test "decoding unknown opcode returns raw return parameters" do
    return_parameters = <<0, "howdy woody!">>
    assert ReturnParameters.decode(<<44, 44, return_parameters::binary>>) == return_parameters
  end

  describe "decode return parameters" do
    test "HCI_Read_Local_Name" do
      assert ReturnParameters.decode(<<20, 12, 0, "Duke Silver">>) == %{
               status: 0,
               status_name: "Success",
               local_name: "Duke Silver"
             }
    end
  end
end
