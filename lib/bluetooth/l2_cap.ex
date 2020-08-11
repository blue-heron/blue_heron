defmodule Bluetooth.L2CAP do
  @moduledoc """
  The Bluetooth Logical Link Control and Adaptation Protocol (L2CAP)
  supports higher level protocol multiplexing, packet segmentation and
  reassembly, and the conveying of quality of service information.

  Volume 3 Part A of the Bluetooth Spec
  """

  alias Bluetooth.HCI.Transport

  @behaviour :gen_statem

  defstruct transport: nil

  @doc """
  Setup L2CAP on a transport
  """
  def start_link(transport) do
    :gen_statem.start_link(__MODULE__, transport, [])
  end

  @impl :gen_statem
  def callback_mode(), do: :state_functions

  @impl :gen_statem
  def init(transport) do
    :ok = Transport.add_event_handler(transport)
    data = %__MODULE__{transport: transport}

    actions = [
      # {:next_event, :internal, :open_transport}
    ]

    {:ok, :closed, data, actions}
  end
end
