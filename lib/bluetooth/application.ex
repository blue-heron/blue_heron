defmodule Bluetooth.Application do
  @moduledoc false
  require Logger

  use Application

  @spec start(Application.start_type(), any()) ::
          {:ok, pid()} | {:ok, pid(), Application.state()} | {:error, reason :: any()}
  def start(_type, _args) do
    children = []

    opts = [strategy: :rest_for_one, name: Bluetooth.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
