# SPDX-FileCopyrightText: 2023 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.ACLBuffer do
  @moduledoc """
  simple fifo buffer implementation that handles sending ACL packets synchronously without blocking
  """
  use GenServer
  require Logger

  alias BlueHeron.ACL
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
    was_empty? = :queue.is_empty(state.acls)

    acls =
      acl
      |> fragment_acl()
      |> Enum.reduce(state.acls, &:queue.in/2)

    new_state = %{state | acls: acls}

    if was_empty?, do: send(self(), :out)

    {:noreply, new_state}
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

  defp fragment_acl(%ACL{} = acl) do
    case BlueHeron.HCI.Transport.get_setup_param(:acl_data_packet_length) do
      {:ok, max_size} when is_integer(max_size) and max_size > 0 -> ACL.fragment(acl, max_size)
      _ -> [acl]
    end
  end

  defp fragment_acl(acl), do: [acl]
end
