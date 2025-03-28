# SPDX-FileCopyrightText: 2019 Very
#
# SPDX-License-Identifier: MIT
#
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
  Deserialize a service data binary.

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
