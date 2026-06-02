# SPDX-FileCopyrightText: 2026 BlueHeron Contributors
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.PeripheralTest do
  use ExUnit.Case

  alias BlueHeron.GATT.Service
  alias BlueHeron.Peripheral

  setup_all do
    Application.stop(:blue_heron)
    :ok
  end

  setup do
    start_supervised!({PropertyTable, name: BlueHeron.GATT})
    :ok
  end

  describe "add_services/1" do
    test "appends all services to the profile in a single PropertyTable update" do
      PropertyTable.subscribe(BlueHeron.GATT, ["profile"])

      a = %Service{id: :a, type: 0x2800, characteristics: []}
      b = %Service{id: :b, type: 0x2800, characteristics: []}

      assert :ok = Peripheral.add_services([a, b])

      assert_receive %PropertyTable.Event{
                       table: BlueHeron.GATT,
                       property: ["profile"],
                       value: [^a, ^b]
                     }

      refute_receive %PropertyTable.Event{table: BlueHeron.GATT}, 50
      assert PropertyTable.get(BlueHeron.GATT, ["profile"]) == [a, b]
    end

    test "prepends to existing services" do
      seed = %Service{id: :seed, type: 0x2800, characteristics: []}
      PropertyTable.put(BlueHeron.GATT, ["profile"], [seed])

      new = %Service{id: :new, type: 0x2800, characteristics: []}
      assert :ok = Peripheral.add_services([new])

      assert PropertyTable.get(BlueHeron.GATT, ["profile"]) == [new, seed]
    end
  end
end
