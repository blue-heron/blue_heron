defmodule BlueHeron.GATT.Characteristic.Descriptor do
  @moduledoc """
  Struct that represents a GATT characteristic descriptor.
  """
  @opaque t() :: %__MODULE__{
            permissions: integer(),
            value: binary()
          }

  defstruct [:permissions, value: <<0::16>>]

  @doc """
  Create a characteristic with fields taken from the map `args`.

  The following fields are required:
  - `permissions`: The characteristic descriptor property flags. Integer.

  ## Example:

      iex> BlueHeron.GATT.Characteristic.Descriptor.new(%{
      ...>   value: 0x0001,
      ...> })
      %BlueHeron.GATT.Characteristic.Descriptor{permissions: 2, value: <<0,0>>}
  """
  @spec new(args :: map()) :: t()
  def new(args) do
    args =
      Map.take(args, [:permissions])
      |> Map.put(:value, <<0, 0>>)

    struct!(__MODULE__, args)
  end
end
