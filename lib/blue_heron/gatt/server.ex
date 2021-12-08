defmodule BlueHeron.GATT.Server do
  @moduledoc """
  A behaviour module for implementing a GATT server.

  This module handles all generic aspects of the GATT protocol, including MTU
  exchange and service discovery. The callback module is invoked for a
  description of the GATT profile (services and characteristics), as well as
  reading and writing characteristic values.

  Example callback module:

      defmodule MyApp.MyGattServer do
        @behaviour BlueHeron.GATT.Server

        @impl BlueHeron.GATT.Server
        def profile() do
          [
            BlueHeron.GATT.Service.new(%{
              id: :gap,
              type: 0x1800,
              characteristics: [
                BlueHeron.GATT.Characteristic.new(%{
                  id: {:gap, :device_name},
                  type: 0x2A00,
                  properties: 0b0000010
                }),
                BlueHeron.GATT.Characteristic.new(%{
                  id: {:gap, :appearance},
                  type: 0x2A01,
                  properties: 0b0000010
                })
              ]
            }),
            BlueHeron.GATT.Service.new(%{
              id: :my_custom_service,
              type: 0xBB5D5975D8E4853998F51335CDFFE9A,
              characteristics: [
                BlueHeron.GATT.Characteristic.new(%{
                  id: {:my_custom_service, :my_custom_characteristic},
                  type: 0x1234,
                  properties: 0b0001010
                }),
                BlueHeron.GATT.Characteristic.new(%{
                  id: {:my_custom_service, :another_custom_characteristic},
                  type: 0xF018E00E0ECE45B09617B744833D89BA,
                  properties: 0b0001010
                })
              ]
            })
          ]
        end

        @impl BlueHeron.GATT.Server
        def read({:gap, :device_name}) do
          "my-device-name"
        end

        @impl BlueHeron.GATT.Server
        def write({:my_custom_serivce, :my_custom_characteristic}, value) do
          MyApp.DB.insert(:my_custom_characteristic, value)
        end
      end
  """

  alias BlueHeron.ATT.{
    ErrorResponse,
    ExchangeMTURequest,
    ExchangeMTUResponse,
    FindInformationRequest,
    PrepareWriteRequest,
    PrepareWriteResponse,
    ExecuteWriteRequest,
    ExecuteWriteResponse,
    ReadBlobRequest,
    ReadBlobResponse,
    ReadByGroupTypeRequest,
    ReadByGroupTypeResponse,
    ReadByTypeRequest,
    ReadByTypeResponse,
    ReadRequest,
    ReadResponse,
    WriteRequest,
    WriteResponse
  }

  alias BlueHeron.GATT.Service

  @doc """
  Return the list of services that make up the GATT profile of the device.

  This callback is only invoked when the GATT server is started, as the profile
  is assumed to be static.

  To comply with the Bluetooth specification, the profile must include a "GAP"
  service (type UUID 0x1800), which must have characteristics for "Device Name"
  (type UUID 0x2A00) and "Appearance" (type UUID 0x2A01).
  """
  @callback profile() :: [Service.t()]

  @doc """
  Return the value of the characteristic given by `id`.
  The value must be serialized as a binary.
  """
  @callback read(id :: any()) :: binary()

  @doc """
  Handle a write to the characteristic given by `id`.
  """
  @callback write(id :: any(), value :: binary()) :: :ok

  defstruct [:mod, :profile, :mtu, :read_buffer, :write_requests]

  @discover_all_primary_services 0x2800
  @find_included_services 0x2802
  @discover_all_characteristics 0x2803

  @doc false
  def init(mod) do
    profile = hydrate(mod.profile())

    %__MODULE__{
      mod: mod,
      profile: profile,
      mtu: 23,
      read_buffer: <<>>,
      write_requests: []
    }
  end

  @doc false
  def handle(state, request) do
    case request do
      %ExchangeMTURequest{} ->
        exchange_mtu(state, request)

      %ReadByGroupTypeRequest{uuid: @discover_all_primary_services} ->
        discover_all_primary_services(state, request)

      %ReadByTypeRequest{uuid: @find_included_services} ->
        find_included_services(state, request)

      %ReadByTypeRequest{uuid: @discover_all_characteristics} ->
        discover_all_characteristics(state, request)

      %ReadByTypeRequest{} ->
        discover_characteristics_by_uuid(state, request)

      %FindInformationRequest{} ->
        discover_all_characteristic_descriptors(state, request)

      %ReadRequest{} ->
        read_characteristic_value(state, request)

      %ReadBlobRequest{} ->
        read_long_characteristic_value(state, request)

      %WriteRequest{} ->
        write_characteristic_value(state, request)

      %PrepareWriteRequest{} ->
        write_long_characteristic_value(state, request)

      %ExecuteWriteRequest{} ->
        write_long_characteristic_value(state, request)
    end
  end

  defp exchange_mtu(state, _request) do
    {state, %ExchangeMTUResponse{server_rx_mtu: state.mtu}}
  end

  defp discover_all_primary_services(state, request) do
    services =
      Enum.filter(state.profile, fn service ->
        service.handle >= request.starting_handle and service.handle <= request.ending_handle
      end)

    case services do
      [] ->
        {state,
         %ErrorResponse{
           handle: request.starting_handle,
           request_opcode: request.opcode,
           error: :attribute_not_found
         }}

      services_in_range ->
        attribute_data =
          services_in_range
          |> Enum.map(fn service ->
            %ReadByGroupTypeResponse.AttributeData{
              handle: service.handle,
              end_group_handle: service.end_group_handle,
              uuid: service.type
            }
          end)
          |> filter_by_uuid_size()
          |> limit_attribute_count(state.mtu)

        {state, %ReadByGroupTypeResponse{attribute_data: attribute_data}}
    end
  end

  defp find_included_services(state, request) do
    # TODO: Implement
    {state,
     %ErrorResponse{
       handle: request.starting_handle,
       request_opcode: request.opcode,
       error: :attribute_not_found
     }}
  end

  defp discover_all_characteristics(state, request) do
    characteristics =
      state.profile
      |> Enum.flat_map(fn service -> service.characteristics end)
      |> Enum.filter(fn characteristic ->
        characteristic.handle >= request.starting_handle and
          characteristic.handle <= request.ending_handle
      end)

    case characteristics do
      [] ->
        {state,
         %ErrorResponse{
           handle: request.starting_handle,
           request_opcode: request.opcode,
           error: :attribute_not_found
         }}

      characteristics_in_range ->
        attribute_data =
          characteristics_in_range
          |> Enum.map(fn characteristic ->
            %ReadByTypeResponse.AttributeData{
              handle: characteristic.handle,
              uuid: characteristic.type,
              characteristic_properties: characteristic.properties,
              characteristic_value_handle: characteristic.value_handle
            }
          end)
          |> filter_by_uuid_size()
          |> limit_attribute_count(state.mtu)

        {state, %ReadByTypeResponse{attribute_data: attribute_data}}
    end
  end

  defp discover_characteristics_by_uuid(state, request) do
    characteristics =
      state.profile
      |> Enum.filter(fn service ->
        service.handle >= request.starting_handle and
          service.handle <= request.ending_handle
      end)
      |> Enum.flat_map(fn service -> service.characteristics end)
      |> Enum.filter(fn characteristic ->
        characteristic.type == request.uuid and characteristic.handle >= request.starting_handle and
          characteristic.handle <= request.ending_handle
      end)

    case characteristics do
      [] ->
        {state,
         %ErrorResponse{
           handle: request.starting_handle,
           request_opcode: request.opcode,
           error: :attribute_not_found
         }}

      characteristics_in_range ->
        attribute_data =
          characteristics_in_range
          |> Enum.map(fn characteristic ->
            %ReadByTypeResponse.AttributeData{
              handle: characteristic.handle,
              uuid: characteristic.type,
              characteristic_properties: characteristic.properties,
              characteristic_value_handle: characteristic.value_handle
            }
          end)
          |> filter_by_uuid_size()
          |> limit_attribute_count(state.mtu)

        {state, %ReadByTypeResponse{attribute_data: attribute_data}}
    end
  end

  defp discover_all_characteristic_descriptors(state, request) do
    # TODO: Implement
    {state,
     %ErrorResponse{
       handle: request.starting_handle,
       request_opcode: request.opcode,
       error: :attribute_not_found
     }}
  end

  defp read_characteristic_value(state, request) do
    id = find_characteristic_id(state.profile, request.handle)
    value = state.mod.read(id)

    # We cache the value if it's longer than MTU - 1, to avoid inconsistent
    # reads if the value is updated during the read operation. We assume that
    # the client will only attempt to read one characteristic at a time.
    case read_bytes(value, state.mtu - 1) do
      {:partial, partial_value, value} ->
        state = %{state | read_buffer: value}
        {state, %ReadResponse{value: partial_value}}

      {:complete, value} ->
        state = %{state | read_buffer: nil}
        {state, %ReadResponse{value: value}}
    end
  end

  defp read_long_characteristic_value(state, request) do
    id = find_characteristic_id(state.profile, request.handle)

    read_result =
      case state.read_buffer do
        nil ->
          value = state.mod.read(id)
          read_bytes(value, state.mtu - 1, request.offset)

        value ->
          read_bytes(value, state.mtu - 1, request.offset)
      end

    case read_result do
      {:partial, partial_value, value} ->
        state = %{state | read_buffer: value}
        {state, %ReadBlobResponse{value: partial_value}}

      {:complete, value} ->
        state = %{state | read_buffer: nil}
        {state, %ReadBlobResponse{value: value}}
    end
  end

  defp write_characteristic_value(state, request) do
    id = find_characteristic_id(state.profile, request.handle)
    :ok = state.mod.write(id, request.value)

    {state, %WriteResponse{}}
  end

  defp write_long_characteristic_value(state, %PrepareWriteRequest{} = request) do
    state = %{state | write_requests: [request | state.write_requests]}

    {state,
     %PrepareWriteResponse{
       handle: request.handle,
       offset: request.offset,
       value: request.value
     }}
  end

  defp write_long_characteristic_value(state, %ExecuteWriteRequest{flags: 1}) do
    [req | _] = state.write_requests
    id = find_characteristic_id(state.profile, req.handle)

    value =
      state.write_requests
      |> Enum.sort(fn first, second -> first.offset < second.offset end)
      |> Enum.map(fn req -> req.value end)
      |> Enum.into(<<>>)

    :ok = state.mod.write(id, value)
    state = %{state | write_requests: []}

    {state, %ExecuteWriteResponse{}}
  end

  defp write_long_characteristic_value(state, %ExecuteWriteRequest{flags: 0}) do
    state = %{state | write_requests: []}

    {state, %ExecuteWriteResponse{}}
  end

  defp hydrate(profile) do
    # TODO: Check that ID's are unique
    {_next_handle, profile} =
      Enum.reduce(profile, {1, []}, fn service, {next_handle, acc} ->
        service_handle = next_handle

        {next_handle, characteristics} =
          assign_characteristic_handles(service.characteristics, next_handle + 1)

        service = %{
          service
          | handle: service_handle,
            end_group_handle: next_handle - 1,
            characteristics: characteristics
        }

        {next_handle, [service | acc]}
      end)

    Enum.reverse(profile)
  end

  defp assign_characteristic_handles(characteristics, starting_handle) do
    {next_handle, characteristics} =
      Enum.reduce(characteristics, {starting_handle, []}, fn characteristic, {next_handle, acc} ->
        characteristic = %{characteristic | handle: next_handle, value_handle: next_handle + 1}
        {next_handle + 2, [characteristic | acc]}
      end)

    {next_handle, Enum.reverse(characteristics)}
  end

  # Lists of attributes must only contain attributes whose UUID size
  # is the same as the first attribute in the list
  defp filter_by_uuid_size([attr | _] = attributes) do
    target_size = uuid_byte_size(attr.uuid)
    Enum.take_while(attributes, fn attr -> uuid_byte_size(attr.uuid) == target_size end)
  end

  # The serialized size of the response is not allowed to exceed the MTU
  # The serialized size can be calculated as:
  # size = overhead + length(attributes) * bytes_per_attribute
  defp limit_attribute_count(attributes, mtu) do
    {bytes_per_attribute, overhead} =
      case hd(attributes) do
        %ReadByGroupTypeResponse.AttributeData{} = attr ->
          {4 + uuid_byte_size(attr.uuid), 2}

        %ReadByTypeResponse.AttributeData{} = attr ->
          {5 + uuid_byte_size(attr.uuid), 2}
      end

    max_attribute_count = trunc((mtu - overhead) / bytes_per_attribute)

    Enum.take(attributes, max_attribute_count)
  end

  defp uuid_byte_size(uuid) do
    case uuid <= 0xFFFF do
      true -> 2
      false -> 16
    end
  end

  defp find_characteristic_id(profile, characteristic_value_handle) do
    profile
    |> Enum.flat_map(fn service -> service.characteristics end)
    |> Enum.find_value(fn characteristic ->
      if characteristic.value_handle == characteristic_value_handle, do: characteristic.id
    end)
  end

  defp read_bytes(value, length, offset \\ 0) do
    if byte_size(value) - offset > length do
      {:partial, :binary.part(value, offset, length), value}
    else
      {:complete, :binary.part(value, offset, byte_size(value) - offset)}
    end
  end
end
