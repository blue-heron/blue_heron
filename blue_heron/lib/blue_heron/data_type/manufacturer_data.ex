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
defmodule BlueHeron.DataType.ManufacturerData do
  @moduledoc """
  > The Manufacturer Specific data type is used for manufacturer specific data.

  Reference: Core Specification Supplement, Part A, section 1.4.1

  Modules under the `BlueHeron.ManufacturerData` scope should implement the
  `BlueHeron.ManufacturerDataBehaviour` and `BlueHeron.Serializable` behaviours.
  """

  alias BlueHeron.DataType.ManufacturerData.Apple
  require BlueHeron.AssignedNumbers.CompanyIdentifiers, as: CompanyIdentifiers

  @modules [Apple]

  @doc """
  Returns a list of implementation modules.
  """
  def modules, do: @modules

  @doc """
  Serializes manufacturer data.
  """
  def serialize(data)

  Enum.each(@modules, fn
    module ->
      def serialize({unquote(module.company()), data}) do
        data
        |> unquote(module).serialize()
        |> case do
          {:ok, bin} ->
            {:ok, <<unquote(CompanyIdentifiers.id(module.company())), bin::binary>>}

          :error ->
            error = %{
              remaining: data,
              serialized: <<unquote(CompanyIdentifiers.id(module.company()))>>
            }

            {:error, error}
        end
      end
  end)

  def serialize({:error, _} = ret), do: ret

  def serialize(ret), do: {:error, ret}

  @doc """
  Deserialize a manufacturer data binary.
  """
  def deserialize(binary)

  Enum.each(@modules, fn
    module ->
      def deserialize(
            <<unquote(CompanyIdentifiers.id(module.company()))::little, sub_bin::binary>> = bin
          ) do
        case unquote(module).deserialize(sub_bin) do
          {:ok, data} -> {:ok, {unquote(module).company, data}}
          {:error, _} -> {:error, bin}
        end
      end
  end)

  def deserialize(bin), do: {:error, bin}
end
