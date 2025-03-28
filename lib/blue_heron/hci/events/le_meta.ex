# SPDX-FileCopyrightText: 2020 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Event.LEMeta do
  @moduledoc """
  The LE Meta Event is used to encapsulate all LE Controller specific events.

  Reference: Version 5.2, Vol 4, Part E, 7.7.65
  """

  alias __MODULE__

  @typedoc """
  > An LE Controller uses subevent codes to transmit LE specific events from the Controller to the
  > Host. Note: The subevent code will always be the first Event Parameter (See Section 7.7.65).

  Reference: Version 5.2, Vol 4, Part E, 5.4.4
  """
  @type subevent_code :: pos_integer()

  @code 0x3E

  def __code__(), do: @code

  @doc """
  List all available controller and baseband command modules
  """
  @spec list :: [module()]
  def list() do
    Application.spec(:blue_heron, :modules)
    |> Enum.filter(&match?(["BlueHeron", "HCI", "Event", "LEMeta", _mod], Module.split(&1)))
  end

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      subevent_code =
        Keyword.get_lazy(opts, :subevent_code, fn ->
          raise ":subevent_code key required when defining BlueHeron.HCI.Event.LEMeta.__using__/1"
        end)

      use BlueHeron.HCI.Event, code: LEMeta.__code__()

      @subevent_code subevent_code

      def __subevent_code__(), do: @subevent_code
    end
  end
end
