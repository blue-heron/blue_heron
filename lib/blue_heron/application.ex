# SPDX-FileCopyrightText: 2024 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    all_env = Application.get_all_env(:blue_heron)
    transport_args = Keyword.get(all_env, :transport, [])
    smp_args = Keyword.get(all_env, :smp, [])
    broadcaster_args = Keyword.get(all_env, :broadcaster, [])

    children = [
      {PropertyTable, name: BlueHeron.GATT},
      {Registry,
       [
         keys: :duplicate,
         name: BlueHeron.Registry,
         partitions: System.schedulers_online()
       ]},
      BlueHeron.ACLBuffer,
      {BlueHeron.Broadcaster, broadcaster_args},
      {BlueHeron.SMP, smp_args},
      BlueHeron.Peripheral,
      {BlueHeron.HCI.Transport, transport_args}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BlueHeron.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
