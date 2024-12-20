defmodule BlueHeron.ACLBuffer do
  @moduledoc """
  simple fifo buffer implementation that handles sending ACL packets synchronously without blocking
  """
  use GenServer
  require Logger

  alias BlueHeron.HCI.Event.NumberOfCompletedPackets

  @doc "queue up a message for output"
  def buffer(acl) do
    GenServer.cast(__MODULE__, {:buffer, acl})
  end

  def start_link(args) do
    GenServer.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl GenServer
  def init(_args) do
    :ok = BlueHeron.Registry.subscribe()
    {:ok, %{acls: :queue.new()}}
  end

  @impl GenServer
  def handle_cast({:buffer, acl}, state) do
    new_state = %{state | acls: :queue.in(acl, state.acls)}

    case :queue.out(state.acls) do
      {:empty, _do_not_use_this} ->
        # queue is empty, so send now
        send(self(), :out)
        {:noreply, new_state}

      {{:value, _acl_do_not_use}, _do_not_use_this} ->
        # Logger.warning(%{buffering_acl_message: inspect(acl, base: :hex)})
        # there are already items in the queue, so don't send yet
        {:noreply, new_state}
    end
  end

  @impl GenServer
  def handle_info(:out, %{acls: acls} = state) do
    case :queue.out(acls) do
      {{:value, acl}, acls} ->
        :ok = BlueHeron.HCI.Transport.send_acl(acl)
        {:noreply, %{state | acls: acls}}

      {:empty, acls} ->
        {:noreply, %{state | acls: acls}}
    end
  end

  def handle_info({:BLUETOOTH_EVENT_STATE, :HCI_STATE_WORKING}, state) do
    {:noreply, state}
  end

  def handle_info({:HCI_EVENT_PACKET, %NumberOfCompletedPackets{} = _event}, state) do
    send(self(), :out)
    {:noreply, state}
  end

  def handle_info({:HCI_EVENT_PACKET, _}, state) do
    {:noreply, state}
  end

  def handle_info({:HCI_ACL_DATA_PACKET, _}, state) do
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end
end
