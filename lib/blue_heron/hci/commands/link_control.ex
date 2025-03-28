# SPDX-FileCopyrightText: 2020 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Command.LinkControl do
  alias __MODULE__, as: LC
  @ogf 0x01

  @moduledoc """
  HCI commands for working with Link Control.

  * OGF: `#{inspect(@ogf, base: :hex)}`

  > The Link Control commands allow a Controller to control connections to other BR/EDR
  > Controllers. Some Link Control commands are used only with a BR/EDR Controller
  > whereas other Link Control commands are also used with an LE Controller.

  Reference: Version 5.2, Vol 4, Part E, 7.1
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
      &match?(["BlueHeron", "HCI", "Command", "LinkControl", _mod], Module.split(&1))
    )
  end

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      ocf =
        Keyword.get_lazy(opts, :ocf, fn ->
          raise ":ocf key required when defining HCI.Command.LinkControl.__using__/1"
        end)

      use BlueHeron.HCI.Command, Keyword.put(opts, :ogf, LC.__ogf__())

      @ocf ocf
      @opcode BlueHeron.HCI.Command.opcode(LC.__ogf__(), @ocf)

      def __ocf__(), do: @ocf
      def __opcode__(), do: @opcode
    end
  end
end
