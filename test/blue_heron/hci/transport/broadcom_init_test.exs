# SPDX-FileCopyrightText: 2024 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Transport.BroadcomInitTest do
  use ExUnit.Case

  alias BlueHeron.HCI.Transport.BroadcomInit
  alias BlueHeron.HCI.Command.{ControllerAndBaseband, VendorSpecific}

  describe "broadcom?/1" do
    test "returns true for Broadcom manufacturer ID" do
      assert BroadcomInit.broadcom?(15)
    end

    test "returns false for other manufacturer IDs" do
      refute BroadcomInit.broadcom?(0)
      refute BroadcomInit.broadcom?(10)
      refute BroadcomInit.broadcom?(29)
    end
  end

  describe "vendor_init_commands/2" do
    test "returns empty list for unknown LMP subversion" do
      setup_params = %{lmp_pal_subversion: 0x0000}
      assert [] == BroadcomInit.vendor_init_commands(setup_params)
    end

    test "returns empty list when firmware file not found" do
      setup_params = %{lmp_pal_subversion: 0x6107}
      assert [] == BroadcomInit.vendor_init_commands(setup_params, "/nonexistent/path")
    end

    test "returns empty list when firmware directory is not readable" do
      setup_params = %{lmp_pal_subversion: 0x6107}
      assert [] == BroadcomInit.vendor_init_commands(setup_params, "/dev/null")
    end

    test "returns correct command sequence for valid firmware" do
      # Create a temporary .hcd file with two records
      dir = System.tmp_dir!()
      firmware_dir = Path.join(dir, "brcm_test_#{System.unique_integer([:positive])}")
      File.mkdir_p!(firmware_dir)

      # Two firmware records: a vendor command with 3 bytes of params, and one with no params
      record1 = <<0x4C, 0xFC, 0x03, 0xAA, 0xBB, 0xCC>>
      record2 = <<0x4E, 0xFC, 0x00>>
      hcd_data = record1 <> record2

      hcd_path = Path.join(firmware_dir, "BCM43430B0.hcd")
      File.write!(hcd_path, hcd_data)

      setup_params = %{lmp_pal_subversion: 0x6107}
      commands = BroadcomInit.vendor_init_commands(setup_params, firmware_dir)

      assert [
               %VendorSpecific.DownloadMinidriver{},
               {:delay, 50},
               {:raw_hci, ^record1},
               {:raw_hci, ^record2},
               {:delay, 250},
               %ControllerAndBaseband.Reset{}
             ] = commands

      # Cleanup
      File.rm_rf!(firmware_dir)
    end

    test "handles empty firmware file" do
      dir = System.tmp_dir!()
      firmware_dir = Path.join(dir, "brcm_test_#{System.unique_integer([:positive])}")
      File.mkdir_p!(firmware_dir)

      hcd_path = Path.join(firmware_dir, "BCM43430B0.hcd")
      File.write!(hcd_path, <<>>)

      setup_params = %{lmp_pal_subversion: 0x6107}
      commands = BroadcomInit.vendor_init_commands(setup_params, firmware_dir)

      # Even with empty firmware, we still get the download minidriver + reset wrapper
      assert [
               %VendorSpecific.DownloadMinidriver{},
               {:delay, 50},
               {:delay, 250},
               %ControllerAndBaseband.Reset{}
             ] = commands

      File.rm_rf!(firmware_dir)
    end

    test "returns empty list when setup_params has no lmp_pal_subversion" do
      assert [] == BroadcomInit.vendor_init_commands(%{})
    end

    test "uses default firmware path when nil is passed" do
      setup_params = %{lmp_pal_subversion: 0x6107}
      # Default path is priv/firmware/brcm which includes bundled firmware
      commands = BroadcomInit.vendor_init_commands(setup_params, nil)
      assert [%VendorSpecific.DownloadMinidriver{} | _] = commands
    end

    test "correct firmware name is used for each chip" do
      dir = System.tmp_dir!()
      firmware_dir = Path.join(dir, "brcm_test_#{System.unique_integer([:positive])}")
      File.mkdir_p!(firmware_dir)

      # Create firmware files for different chips
      for {subversion, filename} <- [
            {0x6106, "BCM43430A1.hcd"},
            {0x6107, "BCM43430B0.hcd"},
            {0x6109, "BCM4345C0.hcd"},
            {0x6119, "BCM4345C0.hcd"}
          ] do
        File.write!(Path.join(firmware_dir, filename), <<0x03, 0x0C, 0x00>>)

        commands =
          BroadcomInit.vendor_init_commands(%{lmp_pal_subversion: subversion}, firmware_dir)

        assert length(commands) > 0,
               "Expected commands for subversion #{inspect(subversion, base: :hex)}"
      end

      File.rm_rf!(firmware_dir)
    end
  end
end
