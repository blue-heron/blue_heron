# SPDX-FileCopyrightText: 2020 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Command.LEController do
  alias __MODULE__, as: LEC
  @ogf 0x08

  @moduledoc """
  HCI commands for working with the LE Controller.

  * OGF: `#{inspect(@ogf, base: :hex)}`

  > The LE Controller Commands provide access and control to various capabilities of the Bluetooth
  > hardware, as well as methods for the Host to affect how the Link Layer manages the piconet,
  > and controls connections.

  Reference: Version 5.2, Vol 4, Part E, 7.8
  """

  @doc false
  def __ogf__(), do: @ogf

  @doc """
  List all available LE Controller command modules
  """
  @spec list :: [module()]
  def list() do
    Application.spec(:blue_heron, :modules)
    |> Enum.filter(
      &match?(["BlueHeron", "HCI", "Command", "LEController", _mod], Module.split(&1))
    )
  end

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      ocf =
        Keyword.get_lazy(opts, :ocf, fn ->
          raise ":ocf key required when defining HCI.Command.LEController.__using__/1"
        end)

      use BlueHeron.HCI.Command, Keyword.put(opts, :ogf, LEC.__ogf__())

      @ocf ocf
      @opcode BlueHeron.HCI.Command.opcode(LEC.__ogf__(), @ocf)

      def __ocf__(), do: @ocf
      def __opcode__(), do: @opcode
    end
  end
end
