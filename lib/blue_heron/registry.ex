defmodule BlueHeron.Registry do
  @moduledoc """
  Handles internal message passing of BlueHeron's components
  """

  @pubsub "pubsub"

  @doc """
  Subscribe to HCI events
  """
  @spec subscribe() :: :ok
  def subscribe() do
    with {:ok, _} <- Registry.register(__MODULE__, @pubsub, nil) do
      :ok
    end
  end

  @doc false
  @spec broadcast(term()) :: :ok
  def broadcast(message) do
    Registry.dispatch(__MODULE__, @pubsub, fn entries ->
      for {pid, _data} <- entries, do: send(pid, message)
    end)

    :ok
  end
end
