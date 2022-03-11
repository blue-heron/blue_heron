defmodule BlueHeron.GATT.Service do
  @moduledoc """
  Struct that represents a GATT service.
  """
  @type id :: term()

  @opaque t() :: %__MODULE__{
            id: id,
            type: non_neg_integer(),
            characteristics: [BlueHeron.GATT.Characteristic.t()],
            handle: any(),
            end_group_handle: any()
          }

  defstruct [
    :id,
    :type,
    :characteristics,
    :handle,
    :end_group_handle
  ]

  @doc """
  Create a service with fields taken from the map `args`.

  The following fields are required:
  - `id`: A user-defined term to identify the service. Must be unique within the device profile.
     Can be any Erlang term.
  - `type`: The service type UUID. Can be a 2- or 16-byte byte UUID. Integer.
  - `characteristics`: A list of characteristics.

  ## Example:

      iex> BlueHeron.GATT.Service.new(%{
      ...>   id: :gap,
      ...>   type: 0x1800,
      ...>   characteristics: [
      ...>     BlueHeron.GATT.Characteristic.new(%{
      ...>       id: {:gap, :device_name},
      ...>       type: 0x2A00,
      ...>       properties: 0b00000010
      ...>     })
      ...>   ]
      ...> })
      %BlueHeron.GATT.Service{id: :gap, type: 0x1800, characteristics: [%BlueHeron.GATT.Characteristic{id: {:gap, :device_name}, type: 0x2A00, properties: 2}]}
  """
  @spec new(args :: map()) :: t()
  def new(args) do
    args = Map.take(args, [:id, :type, :characteristics])

    struct!(__MODULE__, args)
  end
end
