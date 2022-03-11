defmodule BlueHeron.GATT.Characteristic do
  @moduledoc """
  Struct that represents a GATT characteristic.
  """

  @type id :: term()

  @opaque t() :: %__MODULE__{
            id: id,
            type: non_neg_integer(),
            properties: non_neg_integer(),
            descriptor: nil | map(),
            handle: any(),
            value_handle: any(),
            descriptor_handle: any()
          }

  defstruct [:id, :type, :properties, :descriptor, :handle, :value_handle, :descriptor_handle]

  @doc """
  Create a characteristic with fields taken from the map `args`.

  The following fields are required:
  - `id`: A user-defined term to identify the characteristic. Must be unique within the device profile.
     Can be any Erlang term.
  - `type`: The characteristic type UUID. Can be a 2- or 16-byte byte UUID. Integer.
  - `properties`: The characteristic property flags. Integer.

  ## Example:

      iex> BlueHeron.GATT.Characteristic.new(%{
      ...>   id: :fancy_key,
      ...>   type: 0x2e0f8e717a7d4690998377626bc6b657,
      ...>   properties: 0b00000010
      ...> })
      %BlueHeron.GATT.Characteristic{id: :fancy_key, type: 0x2e0f8e717a7d4690998377626bc6b657, properties: 2}
  """
  @spec new(args :: map()) :: t()
  def new(args) do
    args = Map.take(args, [:id, :type, :properties, :descriptor])
    struct!(__MODULE__, args)
  end
end
