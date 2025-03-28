# SPDX-FileCopyrightText: 2019 Very
#
# SPDX-License-Identifier: MIT
#
defmodule BlueHeron.ManufacturerDataBehaviour do
  @moduledoc """
  Defines a behaviour that manufacturer data modules should implement.
  """

  @doc """
  Returns the company associated with some manufacturer data.

  See: `BlueHeron.CompanyIdentifiers`
  """
  @callback company :: String.t()
end
