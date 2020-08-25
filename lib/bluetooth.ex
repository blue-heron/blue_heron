defmodule Bluetooth do
  @moduledoc """
  WIP Bluetooth library
  """
  alias Bluetooth.{
    Context,
    HCI.Transport
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

  @doc "Subscribe to HCI events"
  def add_event_handler(%Context{transport: transport}) when is_pid(transport) do
    Transport.add_event_handler(transport)
  end

  @doc "Writes an HCI command via the transport"
  def hci_command(%Context{transport: transport}, %{opcode: _} = packet) do
    Transport.command(transport, packet)
  end

  @doc "Writes an HCI command via the transport"
  def acl(%Context{transport: transport}, packet) do
    Transport.acl(transport, packet)
  end
end
