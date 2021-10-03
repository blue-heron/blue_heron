defmodule BlueHeron.GATT.ServerTest do
  use ExUnit.Case

  alias BlueHeron.GATT.{Characteristic, Server, Service}

  alias BlueHeron.ATT.{
    ErrorResponse,
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

  defmodule TestServer do
    @behaviour Server

    @impl Server
    def profile() do
      [
        Service.new(%{
          id: :gap,
          type: 0x1800,
          characteristics: [
            Characteristic.new(%{
              id: {:gap, :device_name},
              type: 0x2A00,
              properties: 0b0000010
            }),
            Characteristic.new(%{
              id: {:gap, :appearance},
              type: 0x2A01,
              properties: 0b0000010
            })
          ]
        }),
        Service.new(%{
          id: :gatt,
          type: 0x1801,
          characteristics: [
            Characteristic.new(%{
              id: {:gatt, :service_changed},
              type: 0x2A05,
              properties: 0b00100000
            })
          ]
        }),
        Service.new(%{
          id: :custom_service_1,
          type: 0xBB5D5975D8E4853998F51335CDFFE9A,
          characteristics: [
            Characteristic.new(%{
              id: {:custom_service_1, :short_uuid},
              type: 0x1234,
              properties: 0b0001010
            }),
            Characteristic.new(%{
              id: {:custom_service_1, :long_uuid},
              type: 0xF018E00E0ECE45B09617B744833D89BA,
              properties: 0b0001010
            })
          ]
        }),
        Service.new(%{
          id: :custom_service_2,
          type: 0xBB5D5975D8E4853998F51335CDFFE9B,
          characteristics: [
            Characteristic.new(%{
              id: {:custom_service_2, :short_uuid},
              type: 0x1234,
              properties: 0b0001010
            }),
            Characteristic.new(%{
              id: {:custom_service_2, :long_uuid},
              type: 0xF018E00E0ECE45B09617B744833D89BB,
              properties: 0b0001010
            })
          ]
        })
      ]
    end

    @impl Server
    def read({:gap, :device_name}) do
      "test-device"
    end

    def read({:custom_service_1, :short_uuid}) do
      "a-value-longer-than-22-bytes"
    end

    @impl Server
    def write({:custom_service_1, :short_uuid}, value) do
      send(self(), value)
      :ok
    end
  end

  test "discover all primary services" do
    state = Server.init(TestServer)

    # First, request primary services in the entire handle range
    {state, response} =
      Server.handle(state, %ReadByGroupTypeRequest{
        uuid: 0x2800,
        starting_handle: 0x0001,
        ending_handle: 0xFFFF
      })

    # The Server must only return the :gap and :gatt service, as :test_service is of a
    # different UUID length.
    # The end_group_handle must be 0x0005, as that is the handle of the last
    # attribute in the :gap service (the characteristic value handle for
    # :appearance)
    assert %ReadByGroupTypeResponse{
             attribute_data: [
               %ReadByGroupTypeResponse.AttributeData{
                 handle: 0x0001,
                 end_group_handle: 0x0005,
                 uuid: 0x1800
               },
               %ReadByGroupTypeResponse.AttributeData{
                 handle: 0x0006,
                 end_group_handle: 0x0008,
                 uuid: 0x1801
               }
             ]
           } = response

    # Next, request primary services in the remaining handle range.
    {state, response} =
      Server.handle(state, %ReadByGroupTypeRequest{
        uuid: 0x2800,
        starting_handle: 0x0009,
        ending_handle: 0xFFFF
      })

    # The Server must now respond with :custom_service_1, as the response size
    # is not big enough to fit two 16-byte UUID attributes
    assert %ReadByGroupTypeResponse{
             attribute_data: [
               %ReadByGroupTypeResponse.AttributeData{
                 handle: 0x0009,
                 end_group_handle: 0x000D,
                 uuid: 0xBB5D5975D8E4853998F51335CDFFE9A
               }
             ]
           } = response

    # Again, request primary services in the remaining handle range.
    {state, response} =
      Server.handle(state, %ReadByGroupTypeRequest{
        uuid: 0x2800,
        starting_handle: 0x000E,
        ending_handle: 0xFFFF
      })

    # The Server must now respond with :custom_service_2
    assert %ReadByGroupTypeResponse{
             attribute_data: [
               %ReadByGroupTypeResponse.AttributeData{
                 handle: 0x000E,
                 end_group_handle: 0x0012,
                 uuid: 0xBB5D5975D8E4853998F51335CDFFE9B
               }
             ]
           } = response

    # Again, request primary services in the remaining handle range.
    {_state, response} =
      Server.handle(state, %ReadByGroupTypeRequest{
        uuid: 0x2800,
        starting_handle: 0x0013,
        ending_handle: 0xFFFF
      })

    # The Server must return an error to indicate there are services in the
    # requested handle range.
    assert %ErrorResponse{error: :attribute_not_found} = response
  end

  test "discover all characteristics" do
    state = Server.init(TestServer)

    # Request all characteristics in the range of the :gap service
    {state, response} =
      Server.handle(state, %ReadByTypeRequest{
        uuid: 0x2803,
        starting_handle: 0x0001,
        ending_handle: 0x0005
      })

    assert %ReadByTypeResponse{
             attribute_data: [
               %ReadByTypeResponse.AttributeData{
                 handle: 0x0002,
                 uuid: 0x2A00,
                 characteristic_properties: 0b00000010,
                 characteristic_value_handle: 0x0003
               },
               %ReadByTypeResponse.AttributeData{
                 handle: 0x0004,
                 uuid: 0x2A01,
                 characteristic_properties: 0b00000010,
                 characteristic_value_handle: 0x0005
               }
             ]
           } = response

    # Request all characteristics in the range of the :gatt service
    {state, response} =
      Server.handle(state, %ReadByTypeRequest{
        uuid: 0x2803,
        starting_handle: 0x0006,
        ending_handle: 0x0008
      })

    # Server must respond with the :service_changed attribute
    assert %ReadByTypeResponse{
             attribute_data: [
               %ReadByTypeResponse.AttributeData{
                 handle: 0x0007,
                 uuid: 0x2A05,
                 characteristic_properties: 0b00100000,
                 characteristic_value_handle: 0x0008
               }
             ]
           } = response

    # Request all characteristics in the range of :custom_service_1
    {state, response} =
      Server.handle(state, %ReadByTypeRequest{
        uuid: 0x2803,
        starting_handle: 0x0009,
        ending_handle: 0x000D
      })

    # Server must only respond with characteristic with short UUID
    assert %ReadByTypeResponse{
             attribute_data: [
               %ReadByTypeResponse.AttributeData{
                 handle: 0x000A,
                 uuid: 0x1234,
                 characteristic_properties: 0b00001010,
                 characteristic_value_handle: 0x000B
               }
             ]
           } = response

    # Request all characteristics in the remaining range of :custom_service_1
    {_state, response} =
      Server.handle(state, %ReadByTypeRequest{
        uuid: 0x2803,
        starting_handle: 0x000C,
        ending_handle: 0x0000D
      })

    # Server must only respond with characteristic with long UUID
    assert %ReadByTypeResponse{
             attribute_data: [
               %ReadByTypeResponse.AttributeData{
                 handle: 0x000C,
                 uuid: 0xF018E00E0ECE45B09617B744833D89BA,
                 characteristic_properties: 0b00001010,
                 characteristic_value_handle: 0x000D
               }
             ]
           } = response
  end

  test "discover characteristics by uuid" do
    state = Server.init(TestServer)

    # Request all characteristics of type 0x2A00 (device name) in the range of
    # the :gap service
    {state, response} =
      Server.handle(state, %ReadByTypeRequest{
        uuid: 0x2A00,
        starting_handle: 0x0001,
        ending_handle: 0x0005
      })

    assert %ReadByTypeResponse{
             attribute_data: [
               %ReadByTypeResponse.AttributeData{
                 handle: 0x0002,
                 uuid: 0x2A00,
                 characteristic_properties: 0b00000010,
                 characteristic_value_handle: 0x0003
               }
             ]
           } = response

    # Request all characteristics of type 0x2A01 (appearance) in the range of
    # the :gap service
    {state, response} =
      Server.handle(state, %ReadByTypeRequest{
        uuid: 0x2A01,
        starting_handle: 0x0001,
        ending_handle: 0x0005
      })

    assert %ReadByTypeResponse{
             attribute_data: [
               %ReadByTypeResponse.AttributeData{
                 handle: 0x0004,
                 uuid: 0x2A01,
                 characteristic_properties: 0b00000010,
                 characteristic_value_handle: 0x0005
               }
             ]
           } = response

    # Request all characteristics of type 0x2A00 (device name) in the range of
    # the :test_service_1 service
    {state, response} =
      Server.handle(state, %ReadByTypeRequest{
        uuid: 0x2A00,
        starting_handle: 0x0009,
        ending_handle: 0x000D
      })

    assert %ErrorResponse{error: :attribute_not_found} = response

    # Request all characteristics of type 0xF018E00E0ECE45B09617B744833D89BA (long uuid) in the range of
    # the :test_service_1 service
    {_state, response} =
      Server.handle(state, %ReadByTypeRequest{
        uuid: 0xF018E00E0ECE45B09617B744833D89BA,
        starting_handle: 0x0009,
        ending_handle: 0x000D
      })

    assert %ReadByTypeResponse{
             attribute_data: [
               %ReadByTypeResponse.AttributeData{
                 handle: 0x000C,
                 uuid: 0xF018E00E0ECE45B09617B744833D89BA,
                 characteristic_properties: 0b00001010,
                 characteristic_value_handle: 0x000D
               }
             ]
           } = response
  end

  test "read short characteristic value" do
    state = Server.init(TestServer)

    {_state, response} = Server.handle(state, %ReadRequest{handle: 0x0003})

    assert %ReadResponse{value: "test-device"} = response
  end

  test "read long characteristic value" do
    state = Server.init(TestServer)
    # Overhead per response is 1 byte
    chunk_size = state.mtu - 1
    expected_value = "a-value-longer-than-22-bytes"

    [{first_chunk, _index} | remaining_indexed_chunks] =
      expected_value
      |> Stream.unfold(fn s -> String.split_at(s, chunk_size) end)
      |> Enum.take_while(fn s -> s != "" end)
      |> Enum.with_index()

    {state, response} = Server.handle(state, %ReadRequest{handle: 0x000B})
    assert %ReadResponse{value: ^first_chunk} = response

    Enum.reduce(remaining_indexed_chunks, state, fn {chunk, index}, state ->
      {state, response} =
        Server.handle(state, %ReadBlobRequest{handle: 0x000B, offset: index * chunk_size})

      assert %ReadBlobResponse{value: ^chunk} = response
      state
    end)
  end

  test "write short characteristic value" do
    state = Server.init(TestServer)

    {_state, response} =
      Server.handle(state, %WriteRequest{handle: 0x0000B, value: "short-value"})

    assert %WriteResponse{} = response

    assert_receive "short-value"
  end

  test "write long characteristic value" do
    state = Server.init(TestServer)
    # Overhead per request & response is 5 bytes
    chunk_size = state.mtu - 5
    expected_value = "a-value-longer-than-22-bytes"

    state =
      expected_value
      |> Stream.unfold(fn s -> String.split_at(s, chunk_size) end)
      |> Enum.take_while(fn s -> s != "" end)
      |> Enum.with_index()
      |> Enum.reduce(state, fn {chunk, index}, state ->
        offset = index * chunk_size

        {state, response} =
          Server.handle(state, %PrepareWriteRequest{
            handle: 0x0000B,
            value: chunk,
            offset: offset
          })

        assert %PrepareWriteResponse{handle: 0x0000B, value: ^chunk, offset: ^offset} = response
        state
      end)

    {_state, response} = Server.handle(state, %ExecuteWriteRequest{flags: 0x01})
    assert %ExecuteWriteResponse{} = response

    assert_receive ^expected_value
  end
end
