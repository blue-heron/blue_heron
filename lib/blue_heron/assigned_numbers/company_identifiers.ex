# MIT License

# Copyright (c) 2019 Very

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
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
