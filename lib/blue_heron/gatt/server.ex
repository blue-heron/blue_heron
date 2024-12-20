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
    FindInformationResponse,
    HandleValueNotification,
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

  alias BlueHeron.GATT.{Characteristic, Service}
  alias BlueHeron.SMP

  defstruct [:profile, :mtu, :read_buffer, :write_requests]

  @discover_all_primary_services 0x2800
  @find_included_services 0x2802
  @discover_all_characteristics 0x2803
  @cccd 0x2902

  @opaque t() :: %__MODULE__{
            profile: [Service.t()],
            mtu: non_neg_integer(),
            read_buffer: binary(),
            write_requests: [binary()]
          }

  @doc false
  def init(profile) do
    profile = hydrate(profile)

    %__MODULE__{
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
        exchange_mtu_request(state, request)

      %ExchangeMTUResponse{} ->
        exchange_mtu_response(state, request)

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

      %ReadRequest{handle: handle} ->
        if require_permission?(state, request, :read_auth) do
          {state,
           %ErrorResponse{
             handle: request.handle,
             request_opcode: request.opcode,
             error: :insufficient_authentication
           }}
        else
          if descriptor = find_descriptor_by_handle(state, handle) do
            read_descriptor_value(state, descriptor)
          else
            read_characteristic_value(state, request)
          end
        end

      %ReadBlobRequest{} ->
        if require_permission?(state, request, :read_auth) do
          {state,
           %ErrorResponse{
             handle: request.handle,
             request_opcode: request.opcode,
             error: :insufficient_authentication
           }}
        else
          read_long_characteristic_value(state, request)
        end

      %WriteRequest{handle: handle} ->
        if require_permission?(state, request, :write_auth) do
          {state,
           %ErrorResponse{
             handle: request.handle,
             request_opcode: request.opcode,
             error: :insufficient_authentication
           }}
        else
          if find_descriptor_by_handle(state, handle) do
            write_descriptor_value(state, handle, request.value)
          else
            write_characteristic_value(state, request)
          end
        end

      %PrepareWriteRequest{} ->
        if require_permission?(state, request, :write_auth) do
          {state,
           %ErrorResponse{
             handle: request.handle,
             request_opcode: request.opcode,
             error: :insufficient_authentication
           }}
        else
          write_long_characteristic_value(state, request)
        end

      %ExecuteWriteRequest{} ->
        if require_permission?(state, request, :write_auth) do
          [%{handle: handle} | _] = state.write_requests

          {state,
           %ErrorResponse{
             handle: handle,
             request_opcode: request.opcode,
             error: :insufficient_authentication
           }}
        else
          write_long_characteristic_value(state, request)
        end

      _ ->
        # Ignore unhandled requests
        {state, nil}
    end
  end

  @doc false
  @spec exchange_mtu(t(), non_neg_integer()) :: {:ok, ExchangeMTURequest.t()}
  def exchange_mtu(_state, mtu) do
    {:ok, %ExchangeMTURequest{client_rx_mtu: mtu}}
  end

  @doc false
  @spec handle_value_notification(t(), Service.id(), Characteristic.id(), binary()) ::
          {:ok, HandleValueNotification.t()} | {:error, term()}
  def handle_value_notification(state, service_id, chararistic_id, data) do
    with {:ok, service} <- find_service(state.profile, service_id),
         {:ok, characteristic} <- find_characteristic(service, chararistic_id),
         :ok <- check_notification_mtu(state.mtu, data) do
      {:ok,
       %HandleValueNotification{
         data: data,
         handle: characteristic.value_handle
       }}
    end
  end

  def dump(state) do
    table =
      for service <- state.profile do
        chars =
          for char <- service.characteristics do
            descriptor =
              if char.descriptor,
                do: [
                  "\n     ",
                  IO.ANSI.blue(),
                  "0x#{Integer.to_string(char.descriptor_handle, 16)} ",
                  IO.ANSI.green(),
                  "Descriptor ",
                  IO.ANSI.reset(),
                  "[#{inspect(char.descriptor.value, base: :hex)}]"
                ]

            [
              "\n   ",
              IO.ANSI.blue(),
              "0x#{Integer.to_string(char.handle, 16)} ",
              IO.ANSI.green(),
              "Characteristic ",
              IO.ANSI.reset(),
              "[#{inspect(char.id)}, ",
              IO.ANSI.magenta(),
              "0x#{Integer.to_string(char.type, 16)}",
              IO.ANSI.reset(),
              "]",
              "\n     ",
              IO.ANSI.blue(),
              "0x#{Integer.to_string(char.value_handle, 16)} ",
              IO.ANSI.green(),
              "Value ",
              IO.ANSI.reset(),
              "[0b#{Integer.to_string(char.properties, 2)}]",
              " #{inspect(char.permissions)}",
              descriptor || ""
            ]
          end

        [
          "\n\n",
          IO.ANSI.blue(),
          "0x#{Integer.to_string(service.handle, 16)}",
          IO.ANSI.green(),
          " Service ",
          IO.ANSI.reset(),
          "[#{inspect(service.id)}, ",
          IO.ANSI.magenta(),
          "0x#{Integer.to_string(service.type, 16)}",
          IO.ANSI.reset(),
          "]",
          chars
        ]
      end

    IO.iodata_to_binary(table)
  end

  defp require_permission?(state, %{handle: handle}, permission) do
    p_list = find_characteristic_permissions(state.profile, handle)

    if p_list == nil do
      false
    else
      if permission in p_list and not SMP.authenticated?() do
        true
      else
        false
      end
    end
  end

  defp require_permission?(state, _request, permission) do
    # ExecuteWriteRequest doesn't have a handle, so look
    # it up in the write_requests state
    [req | _] = state.write_requests
    require_permission?(state, req, permission)
  end

  defp exchange_mtu_request(state, _request) do
    {state, %ExchangeMTUResponse{server_rx_mtu: state.mtu}}
  end

  defp exchange_mtu_response(state, response) do
    {%{state | mtu: response.server_rx_mtu}, nil}
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

  defp find_descriptor_by_handle(state, handle) do
    state.profile
    |> Enum.flat_map(fn service -> service.characteristics end)
    |> Enum.find_value(fn characteristic ->
      if characteristic.descriptor_handle == handle do
        characteristic.descriptor
      end
    end)
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
    services =
      Enum.filter(state.profile, fn service ->
        service.handle >= request.starting_handle and
          service.handle <= request.ending_handle
      end)

    characteristics =
      services
      |> Enum.flat_map(fn service -> service.characteristics end)
      |> Enum.filter(fn characteristic ->
        characteristic.type == request.uuid and characteristic.handle >= request.starting_handle and
          characteristic.handle <= request.ending_handle
      end)

    case {services, characteristics} do
      # no matching characteristics
      {_, []} ->
        {state,
         %ErrorResponse{
           handle: request.starting_handle,
           request_opcode: request.opcode,
           error: :attribute_not_found
         }}

      {[service | _], [characteristic]} ->
        # TODO: Handle exceptions and long values
        value = service.read.(characteristic.id)

        attr =
          %ReadByTypeResponse.AttributeData{
            handle: characteristic.handle,
            uuid: characteristic.type,
            value: value,
            characteristic_properties: characteristic.properties,
            characteristic_value_handle: characteristic.value_handle
          }

        {state, %ReadByTypeResponse{attribute_data: [attr]}}

      {_, characteristics_in_range} ->
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
    descriptors =
      state.profile
      |> Enum.flat_map(fn service -> service.characteristics end)
      |> Enum.filter(fn
        %{descriptor: nil} ->
          false

        characteristic ->
          characteristic.descriptor_handle >= request.starting_handle and
            characteristic.descriptor_handle <= request.ending_handle
      end)

    case descriptors do
      [] ->
        {state,
         %ErrorResponse{
           handle: request.starting_handle,
           request_opcode: request.opcode,
           error: :attribute_not_found
         }}

      descriptors_in_range ->
        descriptor_data =
          descriptors_in_range
          |> Enum.map(fn characteristic ->
            %FindInformationResponse.InformationData{
              handle: characteristic.descriptor_handle,
              uuid: @cccd
            }
          end)
          |> filter_by_uuid_size()

        format = if uuid_byte_size(hd(descriptor_data).uuid) == 2, do: 0x1, else: 0x2

        {state,
         %FindInformationResponse{
           format: format,
           information_data: descriptor_data
         }}
    end
  end

  defp find_characteristic(%Service{characteristics: characteristics}, id) do
    Enum.find_value(
      characteristics,
      {:error, :unknown_characteric},
      &check_characteristic(&1, id)
    )
  end

  defp check_characteristic(%Characteristic{id: id} = characteristic, id),
    do: {:ok, characteristic}

  defp check_characteristic(%Characteristic{}, _), do: false

  defp find_service(profile, id) do
    Enum.find_value(profile, {:error, :unknown_service}, &check_service(&1, id))
  end

  defp check_service(%Service{id: id} = service, id), do: {:ok, service}
  defp check_service(%Service{}, _id), do: false

  def check_notification_mtu(mtu, data) when byte_size(data) <= mtu - 3, do: :ok
  def check_notification_mtu(_, _), do: {:error, :payload_too_large}

  defp read_characteristic_value(state, request) do
    service = find_service_by_handle(state.profile, request.handle)
    id = find_characteristic_id(state.profile, request.handle)
    value = service.read.(id)

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

  defp read_descriptor_value(state, descriptor) do
    {state, %ReadResponse{value: descriptor.value}}
  end

  defp read_long_characteristic_value(state, request) do
    service = find_service_by_handle(state.profile, request.handle)
    id = find_characteristic_id(state.profile, request.handle)

    read_result =
      case state.read_buffer do
        nil ->
          value = service.read.(id)
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
    service = find_service_by_handle(state.profile, request.handle)
    id = find_characteristic_id(state.profile, request.handle)

    :ok = service.write.(id, request.value)

    {state, %WriteResponse{}}
  end

  defp write_descriptor_value(state, handle, value) do
    profile = Enum.map(state.profile, &map_service_chars(&1, handle, value))
    {%{state | profile: profile}, %WriteResponse{}}
  end

  defp map_service_chars(service, handle, value) do
    characteristics =
      Enum.map(service.characteristics, fn
        %{descriptor_handle: ^handle} = char ->
          # TODO: probably shouldn't be doing this in the map function,
          # but prevents having to itterate the entire service table again
          if match?(<<0x1, 0>>, value), do: service.subscribe.(char.id)
          if match?(<<0x0, 0>>, value), do: service.unsubscribe.(char.id)
          %{char | descriptor: %{char.descriptor | value: value}}

        char ->
          char
      end)

    %{service | characteristics: characteristics}
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
    service = find_service_by_handle(state.profile, req.handle)
    id = find_characteristic_id(state.profile, req.handle)

    value =
      state.write_requests
      |> Enum.sort(fn first, second -> first.offset < second.offset end)
      |> Enum.map(fn req -> req.value end)
      |> Enum.into(<<>>)

    :ok = service.write.(id, value)
    state = %{state | write_requests: []}

    {state, %ExecuteWriteResponse{}}
  end

  defp write_long_characteristic_value(state, %ExecuteWriteRequest{flags: 0}) do
    state = %{state | write_requests: []}

    {state, %ExecuteWriteResponse{}}
  end

  defp hydrate(profile) when is_list(profile) do
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
    initial = {starting_handle, []}

    {next_handle, characteristics} =
      Enum.reduce(characteristics, initial, &assign_characteristic_handle/2)

    {next_handle, Enum.reverse(characteristics)}
  end

  defp assign_characteristic_handle(
         %Characteristic{descriptor: nil} = characteristic,
         {next_handle, acc}
       ) do
    characteristic = %{characteristic | handle: next_handle, value_handle: next_handle + 1}
    {next_handle + 2, [characteristic | acc]}
  end

  defp assign_characteristic_handle(
         %Characteristic{descriptor: %{}} = characteristic,
         {next_handle, acc}
       ) do
    characteristic = %{
      characteristic
      | handle: next_handle,
        value_handle: next_handle + 1,
        descriptor_handle: next_handle + 2
    }

    {next_handle + 3, [characteristic | acc]}
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

  defp find_service_by_handle(profile, characteristic_value_handle) do
    Enum.find(profile, fn service ->
      Enum.find(service.characteristics, fn characteristic ->
        characteristic.value_handle == characteristic_value_handle
      end)
    end)
  end

  defp find_characteristic_id(profile, characteristic_value_handle) do
    profile
    |> Enum.flat_map(fn service -> service.characteristics end)
    |> Enum.find_value(fn characteristic ->
      if characteristic.value_handle == characteristic_value_handle, do: characteristic.id
    end)
  end

  defp find_characteristic_permissions(profile, characteristic_value_handle) do
    profile
    |> Enum.flat_map(fn service -> service.characteristics end)
    |> Enum.find_value(fn characteristic ->
      if characteristic.value_handle == characteristic_value_handle,
        do: characteristic.permissions
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
