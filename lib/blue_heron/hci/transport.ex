defmodule BlueHeron.HCI.Transport do
  @moduledoc """
  Handles sending and receiving HCI Packets
  """
  require Logger
  use GenServer

  alias BlueHeron.HCI.Command.{
    ControllerAndBaseband,
    InformationalParameters,
    LEController
  }

  import BlueHeron.HCI.Deserializable, only: [deserialize: 1]
  import BlueHeron.HCI.Serializable, only: [serialize: 1]

  @type command_complete :: %BlueHeron.HCI.Event.CommandComplete{}
  @type command_status :: %BlueHeron.HCI.Event.CommandStatus{}

  @doc "Checks if setup is complete on the transport"
  @spec setup_complete?() :: boolean()
  def setup_complete? do
    GenServer.call(__MODULE__, :setup_complete?)
  end

  @doc "Send an HCI frame"
  @spec send_hci(map()) ::
          {:ok, command_complete() | command_status()} | {:error, :setup_incomplete | :timeout}
  def send_hci(frame) do
    GenServer.call(__MODULE__, {:send_hci, frame})
  end

  @doc """
  Buffer an ACL frame to be sent
  """
  @spec buffer_acl(map()) :: :ok
  def buffer_acl(frame) do
    BlueHeron.ACLBuffer.buffer(frame)
  end

  @doc false
  @spec send_acl(map()) :: :ok | {:error, :setup_incomplete}
  def send_acl(frame) do
    GenServer.call(__MODULE__, {:send_acl, frame})
  end

  @setup_params [
    :local_name,
    :acl_packet_length,
    :acl_packet_number,
    :syn_packet_length,
    :syn_packet_number,
    :supported_commands,
    :bd_addr,
    :hci_revision,
    :hci_version,
    :lmp_pal_subversion,
    :lmp_pal_version,
    :manufacturer_name,
    :white_list_size,
    :acl_data_packet_length,
    :total_num_acl_data_packets
  ]

  @type setup_param ::
          :local_name
          | :acl_packet_length
          | :acl_packet_number
          | :syn_packet_length
          | :syn_packet_number
          | :supported_commands
          | :bd_addr
          | :hci_revision
          | :hci_version
          | :lmp_pal_subversion
          | :lmp_pal_version
          | :manufacturer_name
          | :white_list_size
          | :acl_data_packet_length
          | :total_num_acl_data_packets

  @doc """
  Returns the value of a setup param or an error if the transport is not ready yet.
  """
  @spec get_setup_param(setup_param()) :: {:ok, term()} | {:error, :setup_incomplete}
  def get_setup_param(key) when key in @setup_params do
    GenServer.call(__MODULE__, {:get_setup_param, key})
  end

  @default_name "BlueHeron"

  @default_setup_commands [
    %ControllerAndBaseband.Reset{},
    %InformationalParameters.ReadLocalVersion{},
    %InformationalParameters.ReadBdAddr{},
    %ControllerAndBaseband.ReadLocalName{},
    %InformationalParameters.ReadLocalSupportedCommands{},
    %InformationalParameters.ReadBdAddr{},
    %InformationalParameters.ReadBufferSize{},
    # %InformationalParameters.ReadLocalSupportedFeatures{},
    %ControllerAndBaseband.SetEventMask{enhanced_flush_complete: false},
    %ControllerAndBaseband.WriteSimplePairingMode{enabled: true},
    %ControllerAndBaseband.WritePageTimeout{timeout: 0x60},
    %ControllerAndBaseband.WriteClassOfDevice{class: 0x0C027A},
    %ControllerAndBaseband.WriteLocalName{name: @default_name},
    %ControllerAndBaseband.WriteInquiryMode{inquiry_mode: 0x0},
    %ControllerAndBaseband.WriteSecureConnectionsHostSupport{enabled: false},
    %ControllerAndBaseband.WriteScanEnable{scan_enable: 0x01},
    %ControllerAndBaseband.WriteDefaultErroneousDataReporting{enabled: true},
    %LEController.ReadBufferSizeV1{},
    %ControllerAndBaseband.WriteLEHostSupport{le_supported_host_enabled: true},
    %LEController.ReadWhiteListSize{}
  ]

  @default_transport_init_backoff_ms :timer.seconds(5)

  @doc false
  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc false
  def transport_data(<<0x04, hci_bin::binary>>) do
    hci = deserialize(hci_bin)
    GenServer.cast(__MODULE__, {:transport_data, :hci, hci})
  end

  def transport_data(<<0x02, acl_bin::binary>>) do
    acl = BlueHeron.ACL.deserialize(acl_bin)
    GenServer.cast(__MODULE__, {:transport_data, :acl, acl})
  end

  def transport_data(<<0x01, _iso::binary>>) do
    :noop
  end

  @impl GenServer
  def init(args) do
    state = %{
      transport: nil,
      transport_init_backoff_ms: @default_transport_init_backoff_ms,
      transport_init_timer: nil,
      setup_commands: @default_setup_commands,
      current: nil,
      current_timer: nil,
      setup_complete: false,
      caller: nil,
      setup_params: %{}
    }

    send(self(), {:initialize_transport, args})
    {:ok, state}
  end

  @impl GenServer
  def handle_info({:initialize_transport, args}, state) do
    case BlueHeron.HCI.Transport.UART.start_link(args) do
      {:ok, pid} ->
        Logger.info("Initialized HCI Transport: #{inspect(pid)}")
        {:noreply, %{state | transport: pid}, {:continue, :setup_transport}}

      {:error, reason} ->
        Logger.error("Initialize HCI Transport error: #{inspect(reason)}")
        retry_time_ms = state.transport_init_backoff_ms + :timer.seconds(5)

        timer =
          Process.send_after(
            self(),
            {:initialize_transport, args},
            state.transport_init_backoff_ms
          )

        new_state = %{
          state
          | transport: nil,
            transport_init_backoff_ms: retry_time_ms,
            transport_init_timer: timer
        }

        {:noreply, new_state}
    end
  end

  def handle_info(:current_timeout, state) do
    new_state = cancel_timer(state)

    case state.caller do
      nil ->
        Logger.warning("Setup command timeout: #{inspect(state.current)}")
        hci_bin = serialize(state.current)
        :ok = BlueHeron.HCI.Transport.UART.flush(state.transport)
        :ok = BlueHeron.HCI.Transport.UART.send_command(state.transport, hci_bin)
        timer = Process.send_after(self(), :current_timeout, 5000)
        {:noreply, %{new_state | current_timer: timer}}

      caller ->
        Logger.warning("HCI command timeout: #{inspect(state.current)}")
        _ = GenServer.reply(caller, {:error, :timeout})
        {:noreply, %{new_state | current: nil, caller: nil}}
    end
  end

  @impl GenServer
  def handle_continue(:setup_transport, %{setup_commands: [command | rest]} = state) do
    new_state = cancel_timer(state)
    hci_bin = serialize(command)
    :ok = BlueHeron.HCI.Transport.UART.send_command(new_state.transport, hci_bin)
    timer = Process.send_after(self(), :current_timeout, 5000)
    {:noreply, %{new_state | setup_commands: rest, current: command, current_timer: timer}}
  end

  def handle_continue(:setup_transport, %{setup_commands: []} = state) do
    :ok = BlueHeron.Registry.broadcast({:BLUETOOTH_EVENT_STATE, :HCI_STATE_WORKING})
    new_state = cancel_timer(state)
    {:noreply, %{new_state | setup_complete: true}}
  end

  @impl GenServer
  def handle_cast(
        {:transport_data, :hci, packet},
        %{setup_complete: false, current: %{opcode: opcode} = current} = state
      ) do
    case packet do
      %BlueHeron.HCI.Event.CommandComplete{
        opcode: ^opcode,
        return_parameters: %{status: 0} = return
      } ->
        new_setup_params = Map.merge(state.setup_params, Map.delete(return, :status))
        new_state = %{cancel_timer(state) | setup_params: new_setup_params, current: nil}
        {:noreply, new_state, {:continue, :setup_transport}}

      %BlueHeron.HCI.Event.CommandComplete{
        opcode: ^opcode,
        return_parameters: %{status: status} = return
      } ->
        status_message = BlueHeron.ErrorCode.to_atom(status)

        Logger.error(
          "Setup Command error: #{status} (#{inspect(status_message)}) return: #{inspect(return)} command: #{inspect(current)}"
        )

        new_state = %{cancel_timer(state) | current: nil}
        {:noreply, new_state, {:continue, :setup_transport}}

      packet ->
        Logger.error("Unknown HCI packet during setup: #{inspect(packet)}")
        {:noreply, state}
    end
  end

  def handle_cast(
        {:transport_data, :hci, packet},
        %{setup_complete: true, current: %{opcode: opcode}, caller: caller} = state
      ) do
    case packet do
      %BlueHeron.HCI.Event.CommandComplete{
        opcode: ^opcode
      } = command_complete ->
        _ = GenServer.reply(caller, {:ok, command_complete})
        new_state = %{cancel_timer(state) | current: nil, caller: nil}
        {:noreply, new_state}

      %BlueHeron.HCI.Event.CommandStatus{num_hci_command_packets: 1, opcode: ^opcode} =
          command_status ->
        _ = GenServer.reply(caller, {:ok, command_status})
        new_state = %{cancel_timer(state) | current: nil, caller: nil}
        {:noreply, new_state}

      packet ->
        Logger.error("Unknown HCI packet during command: #{inspect(packet)}")
        {:noreply, state}
    end
  end

  def handle_cast(
        {:transport_data, :hci, packet},
        %{setup_complete: true} = state
      ) do
    Logger.info("HCI Packet: #{inspect(packet)}")
    :ok = BlueHeron.Registry.broadcast({:HCI_EVENT_PACKET, packet})
    {:noreply, state}
  end

  def handle_cast(
        {:transport_data, :acl, packet},
        %{setup_complete: true} = state
      ) do
    :ok = BlueHeron.Registry.broadcast({:HCI_ACL_DATA_PACKET, packet})
    {:noreply, state}
  end

  @impl GenServer
  def handle_call({:get_setup_param, param}, _from, %{setup_complete: true} = state) do
    value = Map.fetch!(state.setup_params, param)
    {:reply, {:ok, value}, state}
  end

  def handle_call(
        {:send_hci, command},
        from,
        %{setup_complete: true, current: nil, caller: nil} = state
      ) do
    hci_bin = serialize(command)
    :ok = BlueHeron.HCI.Transport.UART.send_command(state.transport, hci_bin)
    timer = Process.send_after(self(), :current_timeout, 5000)
    {:noreply, %{state | current: command, current_timer: timer, caller: from}}
  end

  def handle_call(
        {:send_acl, acl},
        _from,
        %{setup_complete: true} = state
      ) do
    acl_bin = BlueHeron.ACL.serialize(acl)
    :ok = BlueHeron.HCI.Transport.UART.send_acl(state.transport, acl_bin)
    {:reply, :ok, state}
  end

  def handle_call(:setup_complete?, _from, %{setup_complete: setup_complete} = state) do
    {:reply, setup_complete, state}
  end

  def handle_call(_call, _from, %{setup_complete: false} = state) do
    {:reply, {:error, :setup_incomplete}, state}
  end

  defp cancel_timer(state) do
    if state.current_timer do
      _ = Process.cancel_timer(state.current_timer)
      %{state | current_timer: nil}
    else
      state
    end
  end
end
