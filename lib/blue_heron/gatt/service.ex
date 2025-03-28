# SPDX-FileCopyrightText: 2021 Jon Carstens
# SPDX-FileCopyrightText: 2021 Troels Brødsgaard
# SPDX-FileCopyrightText: 2022 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.GATT.Service do
  @moduledoc """
  Struct that represents a GATT service.
  """
  require Logger

  @type id :: term()

  @type read_fn :: (BlueHeron.GATT.Characteristic.id() -> binary())
  @type write_fn :: (BlueHeron.GATT.Characteristic.id(), binary() -> any())
  @type subscribe_fn :: (BlueHeron.GATT.Characteristic.id() -> any())

  @opaque t() :: %__MODULE__{
            id: id,
            type: non_neg_integer(),
            characteristics: [BlueHeron.GATT.Characteristic.t()],
            handle: any(),
            end_group_handle: any(),
            read: read_fn,
            write: write_fn,
            subscribe: subscribe_fn
          }

  defstruct [
    :id,
    :type,
    :characteristics,
    :handle,
    :end_group_handle,
    :read,
    :write,
    :subscribe,
    :unsubscribe
  ]

  @doc """
  Create a service with fields taken from the map `args`.

  The following fields are required:
  - `id`: A user-defined term to identify the service. Must be unique within the device profile.
     Can be any Erlang term.
  - `type`: The service type UUID. Can be a 2- or 16-byte byte UUID. Integer.
  - `characteristics`: A list of characteristics.
  - `read`: a 1 arity function called when the value of a characteristic should be read.
  - `write`: a 2 arity function called when the value of a characteristic should be written.
  - `subscribe`: a 1 arity function called when the value of a characteristic's value should be indicated.
  - `unsubscribe`: a 1 arity function called when the value of a characteristic's value should stop indicating.

  """
  @spec new(args :: map()) :: t()
  def new(args) do
    args = Map.take(args, [:id, :type, :characteristics, :read, :write, :subscribe, :unsubscribe])

    __MODULE__
    |> struct!(args)
    |> validate_callbacks()
  end

  defp validate_callbacks(service) do
    service
    |> Map.update(:read, &default_read_callback/1, fn
      fun when is_function(fun, 1) -> fun
      _ -> &default_read_callback/1
    end)
    |> Map.update(:write, &default_write_callback/2, fn
      fun when is_function(fun, 2) -> fun
      _ -> &default_write_callback/2
    end)
    |> Map.update(:subscribe, &default_subscribe_callback/1, fn
      fun when is_function(fun, 1) -> fun
      _ -> &default_subscribe_callback/1
    end)
    |> Map.update(:unsubscribe, &default_unsubscribe_callback/1, fn
      fun when is_function(fun, 1) -> fun
      _ -> &default_unsubscribe_callback/1
    end)
  end

  defp default_read_callback(id) do
    Logger.error("Service Read #{inspect(id)}")
    <<0>>
  end

  defp default_write_callback(id, value) do
    Logger.error("Service Write #{inspect(id)} #{inspect(value)}")
    :ok
  end

  defp default_subscribe_callback(id) do
    Logger.error("Service Subscribe #{inspect(id)}")
    :ok
  end

  defp default_unsubscribe_callback(id) do
    Logger.error("Service Unsubscribe #{inspect(id)}")
    :ok
  end
end
