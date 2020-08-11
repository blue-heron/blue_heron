defmodule Bluetooth do
  @moduledoc """
  WIP Bluetooth library
  """
  alias Bluetooth.{
    Context,
    HCI.Transport,
    L2CAP,
    SecurityManager
  }

  @type on_start_error :: {:error, {:already_started, pid()} | term()}

  @doc "Entrypoint to starting a Bluetooth Stack"
  @spec transport(Transport.config()) :: {:ok, Context.t()} | on_start_error()
  def transport(config) do
    case Transport.start_link(config) do
      {:ok, pid} ->
        {:ok, %Context{transport: pid}}

      error ->
        error
    end
  end

  @doc "Starts up the L2CAP statemachine"
  @spec l2cap(Context.t()) :: Context.t()
  def l2cap(%Context{transport: transport} = context) when is_pid(transport) do
    {:ok, l2cap} = L2CAP.start_link(transport)
    %Context{context | l2cap: l2cap}
  end

  @doc "Optionally start the SecurityManager"
  @spec sm(Context.t()) :: Context.t()
  def sm(%Context{transport: transport, l2cap: l2cap} = ctx)
      when is_pid(transport) and is_pid(l2cap) do
    {:ok, sm} = SecurityManager.start_link(ctx)
    %Context{ctx | sm: sm}
  end

  def sm(%Context{}) do
    raise ArgumentError, "Transport and L2CAP must be started before starting SecurityManager"
  end

  @doc "Subscribe to HCI events"
  def add_event_handler(%Context{transport: transport}) when is_pid(transport) do
    Transport.add_event_handler(transport)
  end

  @doc "Writes an HCI command via the transport"
  def hci_command(%Context{transport: transport}, packet) when is_binary(packet) do
    Transport.command(transport, packet)
  end
end
