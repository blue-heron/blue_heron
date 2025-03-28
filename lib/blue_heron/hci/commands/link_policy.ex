# SPDX-FileCopyrightText: 2020 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Command.LinkPolicy do
  alias __MODULE__, as: LP
  @ogf 0x02

  @moduledoc """
  HCI commands for working with the Link Policy.

  * OGF: `#{inspect(@ogf, base: :hex)}`

  > The Link Policy Commands provide methods for the Host to affect
  > how the Link Manager manages the piconet. When Link Policy Commands are
  > used, the LM still controls how Bluetooth piconets and scatternets are
  > established and maintained, depending on adjustable policy parameters.
  > These policy commands modify the Link Manager behavior that can result
  > in changes to the link layer connections with Bluetooth remote devices

  Reference: Version 5.2, Vol 4, Part E, 7.2
  """

  @doc false
  def __ogf__(), do: @ogf

  @doc """
  List all available LE Controller command modules
  """
  @spec list :: [module()]
  def list() do
    Application.spec(:blue_heron, :modules)
    |> Enum.filter(&match?(["BlueHeron", "HCI", "Command", "LinkPolicy", _mod], Module.split(&1)))
  end

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      ocf =
        Keyword.get_lazy(opts, :ocf, fn ->
          raise ":ocf key required when defining HCI.Command.LinkPolicy.__using__/1"
        end)

      use BlueHeron.HCI.Command, Keyword.put(opts, :ogf, LP.__ogf__())

      @ocf ocf
      @opcode BlueHeron.HCI.Command.opcode(LP.__ogf__(), @ocf)

      def __ocf__(), do: @ocf
      def __opcode__(), do: @opcode
    end
  end
end
