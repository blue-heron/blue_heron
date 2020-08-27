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
defmodule BlueHeron.DataType.ServiceData do
  @moduledoc """
  > The Service Data data type consists of a service UUID with the data associated with that
  > service.

  Reference: Core Specification Supplement, Part A, section 1.11.1
  """

  require BlueHeron.AssignedNumbers.GenericAccessProfile, as: GenericAccessProfile

  @description_32 "Service Data - 32-bit UUID"

  @doc """
  Returns the three GAP descriptions encompassed by service data.
  """
  def gap_descriptions, do: [@description_32]

  @doc """
      iex> serialize({"Service Data - 32-bit UUID", %{data: <<5, 6>>, uuid: 67305985}})
      {:ok, <<32, 1, 2, 3, 4, 5, 6>>}
  """
  def serialize({@description_32, %{data: data, uuid: uuid}}) do
    binary = <<
      GenericAccessProfile.id(unquote(@description_32)),
      uuid::little-size(32),
      data::binary
    >>

    {:ok, binary}
  end

  def serialize(_), do: :error

  @doc """
  Deserializes a service data binary.

      iex> deserialize(<<32, 1, 2, 3, 4, 5, 6>>)
      {:ok, {"Service Data - 32-bit UUID", %{data: <<5, 6>>, uuid: 67305985}}}
  """
  def deserialize(<<GenericAccessProfile.id(unquote(@description_32)), bin::binary>>) do
    {status, data} =
      case bin do
        <<uuid::little-size(32), data::binary>> ->
          service_data_32 = %{
            uuid: uuid,
            data: data
          }

          {:ok, service_data_32}

        _ ->
          {:error, bin}
      end

    {status, {@description_32, data}}
  end

  def deserialize(bin), do: {:error, bin}
end
