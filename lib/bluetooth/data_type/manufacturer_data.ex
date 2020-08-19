defmodule Bluetooth.DataType.ManufacturerData do
  @moduledoc """
  > The Manufacturer Specific data type is used for manufacturer specific data.

  Reference: Core Specification Supplement, Part A, section 1.4.1

  Modules under the `Bluetooth.ManufacturerData` scope should implement the
  `Bluetooth.ManufacturerDataBehaviour` and `Bluetooth.Serializable` behaviours.
  """

  alias Bluetooth.DataType.ManufacturerData.Apple
  require Bluetooth.AssignedNumbers.CompanyIdentifiers, as: CompanyIdentifiers

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
  Deserializes a manufacturer data binary.
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
