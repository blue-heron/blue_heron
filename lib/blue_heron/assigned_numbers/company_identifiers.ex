# SPDX-FileCopyrightText: 2019 Very
#
# SPDX-License-Identifier: MIT
#
defmodule BlueHeron.AssignedNumbers.CompanyIdentifiers do
  @moduledoc """
  > Company identifiers are unique numbers assigned by the Bluetooth SIG to member companies
  > requesting one.

  Reference: https://www.bluetooth.com/specifications/assigned-numbers/company-identifiers
  """

  @definitions %{
    0x004C => "Apple, Inc."
  }

  @doc """
  Returns the description associated with `id`.
  """
  def description(id)

  @doc """
  Returns the ID associated with `description`.
  """
  def id(description)

  Enum.each(@definitions, fn
    {id, description} ->
      def description(unquote(id)), do: unquote(description)

      def id(unquote(description)), do: unquote(id)
  end)

  @doc """
  Returns a list of all Company Identifier ids.
  """
  defmacro ids, do: unquote(for {id, _} <- @definitions, do: id)
end
