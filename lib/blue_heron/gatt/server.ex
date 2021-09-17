defmodule BlueHeron.GATT.Server do
  alias BlueHeron.ATT.{
    ErrorResponse,
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

  @callback profile() :: [Service.t()]
  @callback read(any()) :: {:ok, binary()} | {:error, term()}
  @callback write(any(), binary()) :: :ok | {:error, term()}

  defstruct [:mod, :profile, :mtu, :write_handle, :write_buffer]

  @discover_all_primary_services 0x2800
  @find_included_services 0x2802
  @discover_all_characteristics 0x2803

  def init(mod) do
    profile = hydrate(mod.profile())

    %__MODULE__{
      mod: mod,
      profile: profile,
      mtu: 23,
      write_handle: nil,
      write_buffer: ""
    }
  end

  def handle(state, request) do
    case request do
      %ReadByGroupTypeRequest{uuid: @discover_all_primary_services} ->
        discover_all_primary_services(state, request)

      %ReadByTypeRequest{uuid: @find_included_services} ->
        find_included_services(state, request)

      %ReadByTypeRequest{uuid: @discover_all_characteristics} ->
        discover_all_characteristics(state, request)

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

  def discover_all_primary_services(state, request) do
    services =
      Enum.filter(state.profile, fn service ->
        service.primary? and service.handle >= request.starting_handle and
          service.handle <= request.ending_handle
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

  def find_included_services(state, request) do
    services =
      Enum.filter(state.profile, fn service ->
        not service.primary? and service.handle >= request.starting_handle and
          service.handle <= request.ending_handle
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

  def discover_all_characteristics(state, request) do
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

  def discover_all_characteristic_descriptors(state, request) do
    # TODO: Implement
    {state,
     %ErrorResponse{
       handle: request.starting_handle,
       request_opcode: request.opcode,
       error: :attribute_not_found
     }}
  end

  def read_characteristic_value(state, request) do
    id = find_characteristic_id(state.profile, request.handle)
    {:ok, value} = state.mod.read(id)

    # TODO: Might want to cache the value if it's longer than MTU - 1, and then
    # serve the read_long_characteristic_value requests from that cache
    # in order to avoid inconsistent reads if the value is updated during the read operation.
    value =
      if byte_size(value) > state.mtu - 1 do
        :binary.part(value, 0, state.mtu - 1)
      else
        value
      end

    {state, %ReadResponse{value: value}}
  end

  def read_long_characteristic_value(state, request) do
    id = find_characteristic_id(state.profile, request.handle)
    {:ok, value} = state.mod.read(id)

    value =
      if byte_size(value) - request.offset > state.mtu - 1 do
        :binary.part(value, request.offset, state.mtu - 1)
      else
        :binary.part(value, request.offset, byte_size(value) - request.offset)
      end

    {state, %ReadBlobResponse{value: value}}
  end

  def write_characteristic_value(state, request) do
    id = find_characteristic_id(state.profile, request.handle)
    :ok = state.mod.write(id, request.value)

    {state, %WriteResponse{}}
  end

  def write_long_characteristic_value(state, %PrepareWriteRequest{} = request) do
    # TODO: Probably want to store a list of write-operations and only materialize the resulting binary
    # when receiving the ExecuteWriteRequest - in case the PrepareWriteRequest do not arrive in order.
    state = %{
      state
      | write_handle: request.handle,
        write_buffer: state.write_buffer <> request.value
    }

    {state,
     %PrepareWriteResponse{
       handle: request.handle,
       offset: request.offset,
       value: request.value
     }}
  end

  def write_long_characteristic_value(state, %ExecuteWriteRequest{flags: 1}) do
    id = find_characteristic_id(state.profile, state.write_handle)
    :ok = state.mod.write(id, state.write_buffer)
    state = %{state | write_handle: nil, write_buffer: ""}

    {state, %ExecuteWriteResponse{}}
  end

  def write_long_characteristic_value(state, %ExecuteWriteRequest{flags: 0}) do
    state = %{state | write_handle: nil, write_buffer: ""}

    {state, %ExecuteWriteResponse{}}
  end

  defp hydrate(profile) do
    # To each service, assign a handle and end handle
    # assign handle to characteristics as well
    # Maybe also create a characteristic.value_handle => characteristic.id
    # TODO: Check that ID's are unique
    # TODO: Check the services with primary?: false are included in other services
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
  # The serialized size can be calculated as size = overhead + length(attributes) * bytes_per_attribute
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
end
