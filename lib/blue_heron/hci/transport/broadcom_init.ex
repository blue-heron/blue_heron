# SPDX-FileCopyrightText: 2024 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Transport.BroadcomInit do
  @moduledoc """
  Generates the vendor-specific initialization command sequence for
  Broadcom/Cypress/Infineon Bluetooth controllers.

  This module handles firmware downloading from `.hcd` files using
  the Broadcom vendor-specific HCI protocol.
  """

  require Logger

  alias BlueHeron.HCI.Command.{ControllerAndBaseband, VendorSpecific}
  alias BlueHeron.HCI.Transport.UART.FirmwareLoader

  @broadcom_manufacturer_id 15

  @default_firmware_path "/lib/firmware/brcm"

  @doc """
  Returns `true` if the manufacturer ID indicates a Broadcom controller.
  """
  @spec broadcom?(non_neg_integer()) :: boolean()
  def broadcom?(manufacturer_name), do: manufacturer_name == @broadcom_manufacturer_id

  @doc """
  Generate vendor initialization commands for a Broadcom controller.

  Looks up the firmware file based on the chip's LMP subversion, parses it,
  and returns a list of setup commands to be prepended to the standard
  HCI initialization sequence.

  Returns an empty list if no firmware is needed or the firmware file is not found.
  """
  @spec vendor_init_commands(map(), String.t() | nil) :: list()
  def vendor_init_commands(setup_params, firmware_path \\ nil) do
    firmware_path = firmware_path || @default_firmware_path
    lmp_subversion = Map.get(setup_params, :lmp_pal_subversion, 0)

    case FirmwareLoader.firmware_name(lmp_subversion) do
      nil ->
        Logger.info("No firmware mapping for LMP subversion #{inspect(lmp_subversion, base: :hex)}")
        []

      name ->
        hcd_path = Path.join(firmware_path, name)

        case File.read(hcd_path) do
          {:ok, hcd_data} ->
            hcd_commands = FirmwareLoader.parse_hcd(hcd_data)
            Logger.info("Loading Broadcom firmware: #{name} (#{length(hcd_commands)} records)")

            [%VendorSpecific.DownloadMinidriver{}, {:delay, 50}] ++
              Enum.map(hcd_commands, &{:raw_hci, &1}) ++
              [{:delay, 250}, %ControllerAndBaseband.Reset{}]

          {:error, :enoent} ->
            Logger.warning("Broadcom firmware file not found: #{hcd_path}")
            []

          {:error, reason} ->
            Logger.error("Failed to read firmware file #{hcd_path}: #{inspect(reason)}")
            []
        end
    end
  end
end
