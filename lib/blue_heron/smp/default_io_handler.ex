# SPDX-FileCopyrightText: 2024 Connor Rigby
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.SMP.DefaultIOHandler do
  @moduledoc """
  Default IO Handler for SMP
  """

  require Logger

  @behaviour BlueHeron.SMP.IOHandler

  @impl true
  def keyfile, do: {:ok, "/data/blue_heron.term"}

  @impl true
  def passkey(data) do
    Logger.info("SMP Passkey: #{inspect(data)}")
  end

  @impl true
  def status_update(status) do
    Logger.info("SMP Status update: #{inspect(status)}")
  end
end
