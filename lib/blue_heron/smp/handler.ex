defmodule BlueHeron.SMP.IOHandler do
  @moduledoc """
  Callback behavior for handling SMP IO requests
  """

  @doc "returns the path to a file on the filesystem used to store encryption keys"
  @callback keyfile() :: {:ok, Path.t()} | {:error, any()}

  @doc "Should be used to display or otherwise print the passkey used for MITM mitigation"
  @callback passkey(data :: binary()) :: any()

  @typedoc "Type of status event"
  @type status :: :success | :passkey_mismatch | :fail

  @doc "Progress callback used to handle errors or successful pairing"
  @callback status_update(status :: status()) :: any
end
