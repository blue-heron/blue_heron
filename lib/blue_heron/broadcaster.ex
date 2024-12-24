defmodule BlueHeron.Broadcaster do
  @moduledoc """
  Handles Advertisement and Broadcasting

  ## Advertisement Data and Scan Response Data

  both `set_advertising_data` and `set_scan_response_data` take the same binary
  data as an argument. The format is called `AdvertisingData` or `AD` for short in
  the official BLE spec. The format is

    <<length, param, data::binary-size(byte_size(data))>>

  Where `param` can be one of many values defined in the official BLE spec suplement, and each `param`
  has it's own data. Both params have a hard limit of 31 bytes total.
  """

  use GenServer
  require Logger

  alias BlueHeron.HCI.Command.LEController.{
    SetAdvertisingParameters,
    SetAdvertisingData,
    SetScanResponseData,
    SetAdvertisingEnable
  }

  alias BlueHeron.HCI.Event.{
    CommandComplete,
    CommandStatus,
    DisconnectionComplete
  }

  @doc """
  Sets Advertising Parameters for a peripheral.
  Must be called **before** `start_advertising` or **after** `stop_advertising`.

  see [Vol 3] Part C, Section 11 of the BLE core specification.
  Additionally see: Core Specification Supplement, Part A, Data Types Specification
  """
  def set_advertising_parameters(params) do
    GenServer.call(__MODULE__, {:set_advertising_parameters, params})
  end

  @doc """
  Sets Advertising Data for a peripheral.
  Must be called **before** `start_advertising` or **after** `stop_advertising`.

  see [Vol 3] Part C, Section 11 of the BLE core specification.
  Additionally see: Core Specification Supplement, Part A, Data Types Specification
  """
  def set_advertising_data(data) do
    GenServer.call(__MODULE__, {:set_advertising_data, data})
  end

  @doc """
  Sets Scan Response Data for a peripheral.
  Must be called **before** `start_advertising` or **after** `stop_advertising`.

  see [Vol 3] Part C, Section 11 of the BLE core specification.
  Additionally see: Core Specification Supplement, Part A, Data Types Specification
  """
  def set_scan_response_data(data) do
    GenServer.call(__MODULE__, {:set_scan_response_data, data})
  end

  @doc """
  Enable advertisement
  """
  def start_advertising() do
    GenServer.call(__MODULE__, :start_advertising)
  end

  @doc """
  Disable advertisement
  """
  def stop_advertising() do
    GenServer.call(__MODULE__, :stop_advertising)
  end

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl GenServer
  def init(_) do
    :ok = BlueHeron.Registry.subscribe()
    {:ok, %{advertising?: false, ready?: false}}
  end

  @impl GenServer
  def handle_info({:BLUETOOTH_EVENT_STATE, :HCI_STATE_WORKING}, state) do
    {:noreply, %{state | ready?: true}}
  end

  def handle_info({:HCI_EVENT_PACKET, %DisconnectionComplete{}}, state) do
    if state.advertising? do
      Logger.info("Restarting advertising")
      command = SetAdvertisingEnable.new(advertising_enable: true)
      {:reply, _, new_state} = handle_command(command, state)
      {:noreply, new_state}
    else
      {:noreply, state}
    end
  end

  def handle_info({:HCI_EVENT_PACKET, _}, state) do
    {:noreply, state}
  end

  def handle_info({:HCI_ACL_DATA_PACKET, _}, state) do
    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:set_advertising_parameters, params}, _from, state) do
    command = SetAdvertisingParameters.new(params)
    handle_command(command, state)
  end

  def handle_call({:set_advertising_data, data}, _from, state) do
    command = SetAdvertisingData.new(advertising_data: data)
    handle_command(command, state)
  end

  def handle_call({:set_scan_response_data, data}, _from, state) do
    command = SetScanResponseData.new(scan_response_data: data)
    handle_command(command, state)
  end

  def handle_call(:start_advertising, _from, state) do
    command = SetAdvertisingEnable.new(advertising_enable: true)
    {:reply, reply, new_state} = handle_command(command, state)
    {:reply, reply, %{new_state | advertising?: true}}
  end

  def handle_call(:stop_advertising, _from, state) do
    command = SetAdvertisingEnable.new(advertising_enable: false)
    {:reply, reply, new_state} = handle_command(command, state)
    {:reply, reply, %{new_state | advertising?: false}}
  end

  defp handle_command(command, state) do
    case BlueHeron.HCI.Transport.send_hci(command) do
      {:ok, %CommandComplete{return_parameters: %{status: 0}}} ->
        {:reply, :ok, state}

      {:ok, %CommandComplete{return_parameters: %{status: error}}} ->
        {^error, reply, _} = BlueHeron.ErrorCode.to_atom(error)
        {:reply, reply, state}

      {:ok, %CommandStatus{status: 0x00}} ->
        {:reply, :ok, state}

      {:ok, %CommandStatus{status: error}} ->
        {^error, reply, _} = BlueHeron.ErrorCode.to_atom(error)
        {:reply, reply, state}
    end
  end
end
