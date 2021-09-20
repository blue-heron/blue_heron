defmodule BlueHeronScan do
  @moduledoc """
  A scanner to collect AdvertisingReport Manufacturer Specific Data.

  This code evolved from:
  [govee_bulb.ex](https://github.com/blue-heron/blue_heron/blob/main/examples/govee/lib/govee_bulb.ex)

  A useful reference:
  [Overview of BLE device identification](https://reelyactive.github.io/ble-identifier-reference.html)

  ## Tested with
    - [Raspberry Pi Model Zero W](https://github.com/nerves-project/nerves_system_rpi0)
    - [BlueHeronTransportUART](https://github.com/blue-heron/blue_heron_transport_uart)
    - [Govee H5102](https://fccid.io/2AQA6-H5102) Thermo-Hygrometer
    - [Govee H5074](https://fccid.io/2AQA6-H5074) Thermo-Hygrometer
    - Random devices from neighbors and passing cars.😉

  ## Examples

      iex(1)> {:ok, pid} = BlueHeronScan.start_link(:uart, %{device: "ttyS0"})
      {:ok, #PID<0.1995.0>}
      iex(2)> state = :sys.get_state(pid)
      %{
        ctx: #BlueHeron.Context<0.1996.0>,
        devices: %{
          92384742759723 => %{
            76 => <<16, 5, 86, 28, 227, 116, 169>>,
            :time => ~U[2021-09-20 15:54:10.685705Z]
          },
          ...
          181149778439893 => %{
            1 => <<1, 1, 4, 36, 211, 92>>,
            76 => <<2, 21, 73, 78, 84, 69, 76, 76, 73, 95, 82, 79, 67, 75, 83, 95, 72,
              87, 80, 117, 242, 255, 194>>,
            :name => "GVH5102_EED5",
            :time => ~U[2021-09-20 15:54:08.854394Z]
          },
          181149781445015 => %{
            name: "ihoment_H6182_C997",
            time: ~U[2021-09-20 15:54:10.746393Z]
          },
          246390811914386 => %{
            76 => <<2, 21, 73, 78, 84, 69, 76, 76, 73, 95, 82, 79, 67, 75, 83, 95, 72,
              87, 80, 116, 146, 240, 194>>,
            60552 => <<0, 126, 10, 34, 24, 100, 2>>,
            :name => "Govee_H5074_F092",
            :time => ~U[2021-09-20 15:54:10.803376Z]
          }
        }
      }
      iex(3)> 
  """

  use GenServer
  require Logger

  alias BlueHeron.HCI.Command.{
    ControllerAndBaseband.WriteLocalName,
    LEController.SetScanEnable
  }

  alias BlueHeron.HCI.Event.{
    LEMeta.AdvertisingReport,
    LEMeta.AdvertisingReport.Device
  }

  @init_commands [%WriteLocalName{name: "BlueHeronScan"}]

  @default_uart_config %{
    device: "ttyACM0",
    uart_opts: [speed: 115_200],
    init_commands: @init_commands
  }

  @default_usb_config %{
    vid: 0x0BDA,
    pid: 0xB82C,
    init_commands: @init_commands
  }

  @doc """
  Start a linked connection to the Bluetooth module

  ## UART

      iex> {:ok, pid} = BlueHeronScan.start_link(:uart, %{device: "ttyS0"})
      {:ok, #PID<0.111.0>}

  ## USB

      iex> {:ok, pid} = BlueHeronScan.start_link(:usb)
      {:ok, #PID<0.111.0>}
  """
  def start_link(transport_type, config \\ %{})

  def start_link(:uart, config) do
    config = struct(BlueHeronTransportUART, Map.merge(@default_uart_config, config))
    GenServer.start_link(__MODULE__, config, [])
  end

  def start_link(:usb, config) do
    config = struct(BlueHeronTransportUSB, Map.merge(@default_usb_config, config))
    GenServer.start_link(__MODULE__, config, [])
  end

  @impl GenServer
  def init(config) do
    # Create a context for BlueHeron to operate with
    {:ok, ctx} = BlueHeron.transport(config)

    # Subscribe to HCI and ACL events
    BlueHeron.add_event_handler(ctx)

    {:ok, %{ctx: ctx, devices: %{}}}
  end

  # Sent when a transport connection is established
  @impl GenServer
  def handle_info({:BLUETOOTH_EVENT_STATE, :HCI_STATE_WORKING}, state) do
    # Enable BLE Scanning. This will deliver messages to the process mailbox
    # when other devices broadcast
    BlueHeron.hci_command(state.ctx, %SetScanEnable{le_scan_enable: true})
    Logger.info("#{__MODULE__} enabled scanning")
    {:noreply, state}
  end

  # Scan AdvertisingReport packets
  @impl GenServer
  def handle_info(
    {:HCI_EVENT_PACKET, %AdvertisingReport{devices: devices}}, state) do
    {:noreply, Enum.reduce(devices, state, &scan_device/2)}
  end

  # Ignore other HCI Events
  @impl GenServer
  def handle_info({:HCI_EVENT_PACKET, _val}, state) do
    # Logger.debug("#{__MODULE__} ignore HCI Event #{inspect(val)}")
    {:noreply, state}
  end

  defp scan_device(device, state) do
    case device do
      %Device{address: addr, data: data} ->
	Enum.reduce(data, state, fn e, acc ->
	  cond do
	    is_local_name?(e) -> store_local_name(acc, addr, e)
	    is_mfg_data?(e) -> store_mfg_data(acc, addr, e)
	    true -> acc
	  end
	end)
      _ -> state
    end
  end

  defp is_local_name?(val) do
    is_binary(val) && String.starts_with?(val, "\t") && String.valid?(val)
  end

  defp is_mfg_data?(val) do
    is_tuple(val) && elem(val, 0) == "Manufacturer Specific Data"
  end

  defp store_local_name(state, addr, "\t" <> name) do
    device = Map.get(state.devices, addr, %{})
    device = Map.merge(device, %{name: name, time: DateTime.utc_now()})
    %{state | devices: Map.put(state.devices, addr, device)}
  end

  defp store_mfg_data(state, addr, dt) do
    {_, mfg_data} = dt
    <<cid::little-16, sdata::binary>> = mfg_data
    device = Map.get(state.devices, addr, %{})
    device = Map.merge(device, %{cid => sdata, time: DateTime.utc_now()})
    %{state | devices: Map.put(state.devices, addr, device)}
  end

end

defmodule BleAdMfgData do
  @moduledoc """
  Decode AdvertisingReport Manufacturer Specific Data.

  https://reelyactive.github.io/ble-identifier-reference.html
  """

  @doc """
  Print device data collected by BlueHeronScan

  ## Examples

      iex(1)> {:ok, pid} = BlueHeronScan.start_link(:uart, %{device: "ttyS0"})
      {:ok, #PID<0.2012.0>}
      iex(2)> BleAdMfgData.print(:sys.get_state(pid).devices)
      [
        ["26.9˚C 62.1% RH 100%🔋", "Govee_H5074_F092"],
        ["27.2˚C 57.5% RH 92%🔋", "GVH5102_EED5"]
      ]
      iex(3)> 
  """
  def print(devices) do
    Enum.reduce(devices, [], fn {_, dmap}, list ->
      Enum.reduce(dmap, list, fn {k, v}, acc ->
	case print_device(k, v) do
	  nil -> acc
	  s -> [[s, Map.get(dmap, :name, "")] | acc]
	end
      end)
    end)
  end

  # https://github.com/Home-Is-Where-You-Hang-Your-Hack/sensor.goveetemp_bt_hci
  # custom_components/govee_ble_hci/govee_advertisement.py
  # GVH5102
  defp print_device(0x0001, <<_::16, temhum::24, bat::8>>) do
    tem = Float.round(temhum/10000, 1)
    hum = rem(temhum, 1000)/10
    "#{tem}˚C #{hum}% RH #{bat}%🔋"
  end

  # https://github.com/wcbonner/GoveeBTTempLogger
  # goveebttemplogger.cpp
  # bool Govee_Temp::ReadMSG(const uint8_t * const data)
  # Govee_H5074
  defp print_device(0xec88, <<_::8, tem::little-16, hum::little-16,
    bat::8, _::8>>
  ) do
    tem = Float.round(tem/100, 1)
    hum = Float.round(hum/100, 1)
    "#{tem}˚C #{hum}% RH #{bat}%🔋"
  end

  defp print_device(_cid, _data) do
    nil
  end

end
