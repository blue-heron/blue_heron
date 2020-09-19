defmodule BlueHeron.HCI.Command do
  defstruct type: nil, args: %{}, meta: %{}
  @type t() :: %__MODULE__{type: atom(), args: map(), meta: map()}
end
