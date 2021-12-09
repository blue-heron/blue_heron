defmodule BlueHeronScan do
  @moduledoc """
  A scanner to collect Manufacturer Specific Data from AdvertisingReport packets.

  A useful reference:
  [Overview of BLE device identification](https://reelyactive.github.io/ble-identifier-reference.html)

  Tested with:
    - [Raspberry Pi Model Zero W](https://github.com/nerves-project/nerves_system_rpi0)
      - /dev/ttyS0 is the BLE controller transport interface
    - [BlueHeronTransportUART](https://github.com/blue-heron/blue_heron_transport_uart)
    - [Govee H5102](https://fccid.io/2AQA6-H5102) Thermo-Hygrometer
    - [Govee H5074](https://fccid.io/2AQA6-H5074) Thermo-Hygrometer
    - Random devices from neighbors and passing cars.😉

  ## Examples

      iex> {:ok, pid} = BlueHeronScan.start_link(:uart, %{device: "ttyS0"})
      {:ok, #PID<0.10860.0>}
      iex> {:ok, devices} = BlueHeronScan.devices(pid)
      {:ok,
       %{
         9049270267450 => %{name: "SS3", time: ~U[2021-12-09 15:59:01.392458Z]},
         48660401950223 => %{
           784 => <<64, 16, 2, 48>>,
           :time => ~U[2021-12-09 15:59:09.606645Z]
         },
         181149778439893 => %{
           1 => <<1, 1, 3, 112, 82, 73>>,
           :name => "GVH5102_EED5",
           :time => ~U[2021-12-09 15:59:09.457780Z]
         },
         181149781445015 => %{
           name: "ihoment_H6182_C997",
           time: ~U[2021-12-09 15:59:09.545683Z]
         },
         209497230420943 => %{
           name: "ELK-BLEDOM   ",
           time: ~U[2021-12-09 15:59:09.631200Z]
         },
         246390811914386 => %{
           60552 => <<0, 81, 2, 189, 25, 100, 2>>,
           :name => "Govee_H5074_F092",
           :time => ~U[2021-12-09 15:59:09.450767Z]
         }
       }}
      iex> BlueHeronScan.ignore_cids(pid, MapSet.new([6, 76, 117, 784]))
      {:ok, #MapSet<[6, 76, 117, 784]>}
      iex> BlueHeronScan.clear_devices(pid)
      :ok
      iex> {:ok, devices} = BlueHeronScan.devices(pid)
      {:ok,
       %{
         181149778439893 => %{
           1 => <<1, 1, 3, 108, 106, 73>>,
           :name => "GVH5102_EED5",
           :time => ~U[2021-12-09 16:02:01.800281Z]
         },
         181149781445015 => %{
           name: "ihoment_H6182_C997",
           time: ~U[2021-12-09 16:02:02.458660Z]
         },
         209497230420943 => %{
           name: "ELK-BLEDOM   ",
           time: ~U[2021-12-09 16:02:02.337530Z]
         },
         210003231250023 => %{
           name: "ELK-BLEDOM ",
           time: ~U[2021-12-09 16:01:50.546539Z]
         },
         246390811914386 => %{
           60552 => <<0, 84, 2, 182, 25, 100, 2>>,
           :name => "Govee_H5074_F092",
           :time => ~U[2021-12-09 16:02:01.408051Z]
         }
       }}
      iex> BleAdMfgData.print(devices)
      [
        ["6.0˚C 65.8% RH 100%🔋", "Govee_H5074_F092"],
        ["22.4˚C 36.2% RH 73%🔋", "GVH5102_EED5"]
      ]
      iex> BlueHeronScan.disable(pid)
      :scan_disable
      iex> BlueHeronScan.clear_devices(pid)
      :ok
      iex> {:ok, devices} = BlueHeronScan.devices(pid)
      {:ok, %{}}
      iex> BlueHeronScan.enable(pid)
      :ok
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
  Start a linked connection to the Bluetooth module and enable active scanning.

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
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  def start_link(:usb, config) do
    config = struct(BlueHeronTransportUSB, Map.merge(@default_usb_config, config))
    GenServer.start_link(__MODULE__, config, name: __MODULE__)
  end

  @doc """
  Enable BLE scanning. This will deliver messages to the process mailbox
  when other devices broadcast.
  
  Returns `:ok` or `{:error, :not_working}` if uninitialized.
  """
  def enable(pid) do
    GenServer.call(pid, :scan_enable)
  end

  @doc """
  Disable BLE scanning.
  """
  def disable(pid) do
    send(pid, :scan_disable)
  end

  @doc """
  Get devices.

      iex> BlueHeronScan.devices(pid)
      {:ok, %{}}
  """
  def devices(pid) do
    GenServer.call(pid, :devices)
  end

  @doc """
  Clear devices from the state.

      iex> BlueHeronScan.clear_devices(pid)
      :ok
  """
  def clear_devices(pid) when is_pid(pid) do
    GenServer.call(pid, :clear_devices)
  end

  @doc """
  Get or set the company IDs to ignore.

  https://www.bluetooth.com/specifications/assigned-numbers/company-identifiers

  Apple and Microsoft beacons, 76 & 6, are noisy.

  ## Examples

      iex> BlueHeronScan.ignore_cids(pid)
      {:ok, [6, 76]}
      iex> BlueHeronScan.ignore_cids(pid, [6, 76, 117])
      {:ok, [6, 76, 117]}
  """
  def ignore_cids(pid, cids \\ nil) do
    GenServer.call(pid, {:ignore_cids, cids})
  end

  @impl GenServer
  def init(config) do
    # Create a context for BlueHeron to operate with.
    {:ok, ctx} = BlueHeron.transport(config)

    # Subscribe to HCI and ACL events.
    BlueHeron.add_event_handler(ctx)

    {:ok, %{ctx: ctx, working: false, devices: %{}, ignore_cids: [6, 76]}}
  end

  # Sent when a transport connection is established.
  @impl GenServer
  def handle_info({:BLUETOOTH_EVENT_STATE, :HCI_STATE_WORKING}, state) do
    # Enable BLE Scanning. This will deliver messages to the process mailbox
    # when other devices broadcast.
    state = %{state | working: true}
    scan(state, true)
    {:noreply, state}
  end

  # Scan AdvertisingReport packets.
  @impl GenServer
  def handle_info(
    {:HCI_EVENT_PACKET, %AdvertisingReport{devices: devices}}, state) do
    {:noreply, Enum.reduce(devices, state, &scan_device/2)}
  end

  # Ignore other HCI Events.
  @impl GenServer
  def handle_info({:HCI_EVENT_PACKET, _val}, state) do
    # Logger.debug("#{__MODULE__} ignore HCI Event #{inspect(val)}")
    {:noreply, state}
  end

  def handle_info(:scan_disable, state) do
    scan(state, false)
    {:noreply, state}
  end

  @impl GenServer
  def handle_call(:devices, _from, state) do
    {:reply, {:ok, state.devices}, state}
  end

  @impl GenServer
  def handle_call(:clear_devices, _from, state) do
    {:reply, :ok, %{state | devices: %{}}}
  end

  @impl GenServer
  def handle_call({:ignore_cids, cids}, _from, state) do
    cond do
      cids == nil -> {:reply, {:ok, state.ignore_cids}, state}
      Enumerable.impl_for(cids) != nil ->
	{:reply, {:ok, cids}, %{state | ignore_cids: cids}}
      true -> {:reply, {:error, :not_enumerable}, state}
    end
  end

  def handle_call(:scan_enable, _from, state) do
    {:reply, scan(state, true), state}
  end

  defp scan(%{working: false}, _enable) do
    {:error, :not_working}
  end

  defp scan(%{ctx: ctx = %BlueHeron.Context{}}, enable) do
    BlueHeron.hci_command(ctx, %SetScanEnable{le_scan_enable: enable})
    status = if(enable, do: "enabled", else: "disabled")
    Logger.info("#{__MODULE__} #{status} scanning")
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
    unless cid in state.ignore_cids do
      device = Map.get(state.devices, addr, %{})
      device = Map.merge(device, %{cid => sdata, time: DateTime.utc_now()})
      %{state | devices: Map.put(state.devices, addr, device)}
    else
      state
    end
  end

end

defmodule BleAdMfgData do
  @moduledoc """
  Decode AdvertisingReport Manufacturer Specific Data.

  https://www.bluetooth.com/specifications/assigned-numbers/company-identifiers
  """

  @doc """
  Print device data collected by `BlueHeronScan`.

  ## Examples

      iex> {:ok, pid} = BlueHeronScan.start_link(:uart, %{device: "ttyS0"})
      {:ok, #PID<0.2012.0>}
      iex> {:ok, devices} = BlueHeronScan.devices(pid)
      ...
      iex> BleAdMfgData.print(devices)
      [
        ["26.9˚C 62.1% RH 100%🔋", "Govee_H5074_F092"],
        ["27.2˚C 57.5% RH 92%🔋", "GVH5102_EED5"]
      ]
      iex> 
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
