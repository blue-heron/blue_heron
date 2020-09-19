defmodule BlueHeron.HCI.ReturnParameters do
  defstruct type: nil, status: 0, args: %{}, meta: %{}

  @type t() :: %__MODULE__{
          type: atom(),
          args: map(),
          status: BlueHeron.ErrorCode.t(),
          meta: map()
        }
end
