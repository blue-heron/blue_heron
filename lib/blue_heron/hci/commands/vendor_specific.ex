# SPDX-FileCopyrightText: 2024 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Command.VendorSpecific do
  alias __MODULE__, as: VS
  @ogf 0x3F

  @moduledoc """
  Vendor-specific HCI commands.

  * OGF: `#{inspect(@ogf, base: :hex)}`

  These commands are used for chip-specific operations such as firmware
  downloading and baud rate configuration on Broadcom/Cypress/Infineon
  Bluetooth controllers.
  """

  @doc false
  def __ogf__(), do: @ogf

  @doc """
  List all available vendor-specific command modules
  """
  @spec list :: [module()]
  def list() do
    Application.spec(:blue_heron, :modules)
    |> Enum.filter(
      &match?(["BlueHeron", "HCI", "Command", "VendorSpecific", _mod], Module.split(&1))
    )
  end

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      ocf =
        Keyword.get_lazy(opts, :ocf, fn ->
          raise ":ocf key required when defining HCI.Command.VendorSpecific.__using__/1"
        end)

      use BlueHeron.HCI.Command, Keyword.put(opts, :ogf, VS.__ogf__())

      @ocf ocf
      @opcode BlueHeron.HCI.Command.opcode(VS.__ogf__(), @ocf)

      def __ocf__(), do: @ocf
      def __opcode__(), do: @opcode
    end
  end
end
