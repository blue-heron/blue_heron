defmodule Bluetooth.Context do
  @moduledoc "Handle to a Bluetooth stack. Fields shoudl be considered opaque"
  alias Bluetooth.Context

  @enforce_keys [:transport]
  defstruct [:transport]

  @type t() :: %Context{transport: pid()}

  # Context implements Inspect to hide the internals
  # it uses the Transport PID as a unique identifier since
  # it is a required key
  defimpl Inspect do
    @moduledoc false
    @doc false
    def inspect(%{transport: pid}, opts) when is_pid(pid) do
      "#PID" <> content = Inspect.PID.inspect(pid, opts)
      IO.iodata_to_binary(["#Bluetooth.Context", content])
    end
  end
end
