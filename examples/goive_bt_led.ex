defmodule Bluetooth.Example.GoveBTLED do
  @moduledoc """
  Example showing how to use BTLE Scan
  """
  # use GenServer
  require Logger
  @behaviour :gen_statem

  alias Bluetooth.HCI.Command.{
    ControllerAndBaseband,
    LEController.CreateConnection
  }

  alias Bluetooth.HCI.Event.{
    LEMeta.ConnectionComplete,
    DisconnectionComplete
  }

  @usb_config %Bluetooth.HCI.Transport.LibUSB{
    vid: 0x0BDA,
    pid: 0xB82C,
    init_commands: [
      %ControllerAndBaseband.WriteLocalName{name: "BLE Scan Test"}
    ]
  }

  @uart_config %Bluetooth.HCI.Transport.UART{
    device: "ttyACM0",
    uart_opts: [speed: 115200],
    init_commands: []
  }

  @connect_addr 0xA4C1389D1EAD

  @create_connection %CreateConnection{
    connection_interval_max: 0x0018,
    connection_interval_min: 0x0008,
    connection_latency: 0x0004,
    initiator_filter_policy: 0,
    le_scan_interval: 0x0060,
    le_scan_window: 0x0030,
    max_ce_length: 0x0030,
    min_ce_length: 0x0002,
    own_address_type: 0,
    peer_address: @connect_addr,
    peer_address_type: 0,
    supervision_timeout: 0x0048
  }

  # Packet Types
  alias Bluetooth.HCI.Event.LEMeta.AdvertisingReport
  alias Bluetooth.HCI.Command.LEController.SetScanEnable

  @doc "Start a linked connection to the bulb"
  def start_link(transport, config \\ %{})

  def start_link(:uart, config) do
    :gen_statem.start_link(__MODULE__, struct(@uart_config, config), [])
  end

  def start_link(:usb, config) do
    :gen_statem.start_link(__MODULE__, struct(@usb_config, config), [])
  end

  @doc """
  Set the color of the bulb.

      iex()> GoveBTLED.set_color(pid, 0xFFFFFF) # full white
      :ok
      iex()> GoveBTLED.set_color(pid, 0xFF0000) # full red
      :ok
      iex()> GoveBTLED.set_color(pid, 0x00FF00) # full green
      :ok
      iex()> GoveBTLED.set_color(pid, 0x0000FF) # full blue
      :ok
  """
  def set_color(pid, rgb) do
    :gen_statem.call(pid, {:set_color, rgb})
  end

  # gen_statem callbacks

  @impl :gen_statem
  @doc false
  def callback_mode(), do: :state_functions

  @impl :gen_statem
  @doc false
  def init(config) do
    # Initialize everything
    {:ok, ctx} = Bluetooth.transport(config)
    :ok = Bluetooth.add_event_handler(ctx)

    data = %{
      ctx: ctx,
      config: config,
      device: nil,
      connection: nil,
      devices: %{},
      caller: nil
    }

    {:ok, :wait_working, data, []}
  end

  @doc false
  def wait_working(:info, {:BLUETOOTH_EVENT_STATE, :HCI_STATE_WORKING}, data) do
    case Bluetooth.hci_command(data.ctx, %SetScanEnable{le_scan_enable: true}) do
      {:ok, _} ->
        {:next_state, :scan, data}

      error ->
        {:stop, error, data}
    end
  end

  def wait_working(:info, {:HCI_EVENT_PACKET, packet}, _data) do
    Logger.info("Unknown packet for state CONNECT: #{inspect(packet, base: :hex, pretty: true)}")
    :keep_state_and_data
  end

  @doc false
  def scan(:info, {:HCI_EVENT_PACKET, %AdvertisingReport{devices: devices}}, data) do
    device =
      Enum.find(devices, fn
        %AdvertisingReport.Device{address: @connect_addr} -> true
        _ -> false
      end)

    if device do
      Bluetooth.hci_command(data.ctx, %SetScanEnable{le_scan_enable: false})
      actions = [{:next_event, :internal, :create_connection}]
      {:next_state, :connect, %{data | device: device}, actions}
    else
      data =
        Enum.reduce(devices, data, fn
          device, data ->
            put_device(device.address, device, data)
        end)

      {:keep_state, data}
    end
  end

  def scan(:info, {:HCI_EVENT_PACKET, packet}, _data) do
    Logger.info("Unknown packet for state SCAN: #{inspect(packet, base: :hex, pretty: true)}")
    :keep_state_and_data
  end

  def scan({:call, from}, _call, data) do
    {:keep_state, data, [{:reply, from, {:error, :disconnected}}]}
  end

  @doc false
  def connect(:internal, :create_connection, data) do
    case Bluetooth.hci_command(data.ctx, @create_connection) do
      {:ok, result} ->
        Logger.info("Connecting: #{inspect(result)}")
        :keep_state_and_data

      error ->
        {:stop, error, data}
    end
  end

  def connect(:info, {:HCI_EVENT_PACKET, %AdvertisingReport{}}, _data) do
    :keep_state_and_data
  end

  # def connect(:info, {:HCI_EVENT_PACKET, %ConnectionComplete{} = connection}, data) do
  #   actions = [{:next_event, :internal, :exchange_mtu}]
  #   {:next_state, :exchange_mtu, %{data | connection: connection}, actions}
  # end

  def connect(:info, {:HCI_EVENT_PACKET, %ConnectionComplete{} = connection}, data) do
    {:next_state, :ready, %{data | connection: connection}, []}
  end

  def connect(:info, {:HCI_EVENT_PACKET, packet}, _data) do
    Logger.info("Unknown packet for state CONNECT: #{inspect(packet, base: :hex, pretty: true)}")
    :keep_state_and_data
  end

  def connect({:call, from}, _call, data) do
    {:keep_state, data, [{:reply, from, {:error, :disconnected}}]}
  end

  # @doc false
  # def exchange_mtu(:internal, :exchange_mtu, data) do
  #   Bluetooth.acl(
  #     data.ctx,
  #     <<data.connection.connection_handle::little-12, 0::4, 0x7, 0x0, 0x3, 0x0, 0x4, 0x0, 0x2,
  #       0x9B, 0x6>>
  #   )

  #   :keep_state_and_data
  # end

  # def exchange_mtu(:info, {:HCI_EVENT_PACKET, packet}, _data) do
  #   Logger.info(
  #     "Unknown packet for state exchange_mtu: #{inspect(packet, base: :hex, pretty: true)}"
  #   )

  #   :keep_state_and_data
  # end

  # def exchange_mtu(
  #       :info,
  #       {:HCI_ACL_DATA_PACKET,
  #        <<_handle::little-12, _pb::2, _bc::2, length::little-16, _acl_data::binary-size(length)>>},
  #       data
  #     ) do
  #   actions = []
  #   {:next_state, :ready, data, actions}
  # end

  @doc false
  def ready({:call, from}, {:set_color, rgb}, data) do
    data_len = 27
    l2cap_len = 23
    cid = 0x4
    value = <<0x33, 0x5, 0x2, rgb::24, 0, rgb::24, 0, 0, 0, 0, 0, 0, 0, 0, 0>>
    checksum = calculate_xor(value, 0)

    acl = <<data.connection.connection_handle::little-12, 0::4, data_len::little-16,
      l2cap_len::little-16, cid::little-16, 0x52, 0x0015::little-16, value::binary-19,
      checksum::8>>
    Bluetooth.acl(data.ctx, acl)
    {:keep_state, %{data | caller: from}}
  end

  def ready(:info, {:HCI_ACL_DATA_PACKET, _reply}, data) do
    if data.caller do
      {:keep_state, data, [{:reply, data.caller, :ok}]}
    else
      :keep_state_and_data
    end
  end

  def ready(:info, {:HCI_EVENT_PACKET, %DisconnectionComplete{reason_name: reason}}, data) do
    Logger.warn "Disconnected: #{reason}"
    actions = [{:next_event, :internal, :create_connection}]
    {:next_state, :connect, %{data | connection: nil}, actions}
  end

  # def send_write(:internal, :send_write, data) do
  #   acl =
  #     <<data.connection.connection_handle::little-12, 0::4, 0x1B, 0x0, 0x17, 0x0, 0x4, 0x0, 0x52,
  #       0x15, 0x0, 0x33, 0x5, 0x2, 0xFF, 0x0, 0x0, 0x0, 0xFF, 0x89, 0x12, 0x0, 0x0, 0x0, 0x0, 0x0,
  #       0x0, 0x0, 0x0, 0x0, 0xAF>>

  #   Bluetooth.acl(data.ctx, acl)
  #   :keep_state_and_data
  # end

  # def send_write(
  #       :info,
  #       {:HCI_ACL_DATA_PACKET,
  #        <<_handle::little-12, _pb::2, _bc::2, length::little-16, _acl_data::binary-size(length)>>},
  #       data
  #     ) do
  #   :keep_state_and_data
  # end

  # def att_read_by_group(:internal, :att_read_by_group, data) do
  #   Logger.info "ATT READ BY GROUP"
  #   Bluetooth.acl(data.ctx, <<data.connection.connection_handle::little-12, 0::4, 0xB, 0x0, 0x7, 0x0, 0x4, 0x0, 0x10, 0x1, 0x0, 0xFF, 0xFF, 0x0, 0x28>>)
  #   :keep_state_and_data
  # end

  # def att_read_by_group(:info, {:HCI_EVENT_PACKET, packet}, _data) do
  #   Logger.info("Unknown packet for state att_read_by_group: #{inspect(packet, base: :hex, pretty: true)}")
  #   :keep_state_and_data
  # end

  # def att_read_by_group(:info, {:HCI_ACL_DATA_PACKET, <<_handle::little-12, _pb::2, _bc::2, length::little-16, acl_data::binary-size(length)>>}, data) do
  #   # l2cap
  #   <<_l2cap_length::little-16, 0x4::little-16, att::binary>> = acl_data
  #   # <<opcode::8, length::8, handles::binary>> = att
  #   <<0x11::8, _length::8, _handles::binary>> = att
  #   # IO.inspect(att, base: :hex, limit: :infinity, label: "ATT Data")

  #   actions = [{:next_event, :internal, :att_read_by_group}]
  #   {:next_state, :att_read_by_group, data, actions}
  # end

  defp put_device(address, device_report, %{devices: devices} = data) do
    %{data | devices: Map.put(devices, address, device_report)}
  end

  defp calculate_xor(<<>>, checksum), do: checksum

  defp calculate_xor(<<x::8, rest::binary>>, checksum) do
    calculate_xor(rest, :erlang.bxor(checksum, x))
  end
end
