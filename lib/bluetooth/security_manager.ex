defmodule Bluetooth.SecurityManager do
  @moduledoc """
  The Security Manager (SM) defines the protocol and behavior to manage pairing,
  authentication, and encryption between LE-only or BR/EDR/LE devices.

  Volume 3 Part H of the Bluetooth Spec
  """

  use GenServer
  alias Bluetooth.{Context, HCI.Transport}

  @doc "Optionally start the security manager"
  def start_link(%Context{} = context) do
    GenServer.start_link(__MODULE__, %Context{} = context)
  end

  @impl GenServer
  def init(context) do
    :ok = Transport.add_event_handler(context.transport)
    {:ok, %{l2cap: context.l2cap, transport: context.transport}}
  end
end
