defmodule BlueHeron.Context do
  @moduledoc "Handle to a Bluetooth stack. Fields should be considered opaque"
  alias BlueHeron.Context

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
      IO.iodata_to_binary(["#BlueHeron.Context", content])
    end
  end
end
