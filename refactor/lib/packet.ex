defmodule BlueHeron.HCI.Packet do
  alias BlueHeron.HCI.{ReturnParameters}

  # FH: I don't know what all the options are for decoding return parameters.
  #     For example, are there commands with multiple return parameters than need
  #     to collect a few before the response is given?
  #     Or, is it stupid simple where you send a command and you always wait for
  #     a response of the same type?
  @type response_decoder() :: (binary() -> {:ok, ReturnParameters.t()} | {:error, :not_response})

  defstruct data: <<>>, decode_response: nil, meta: %{}
  @type t() :: %__MODULE__{data: binary(), decode_response: response_decoder(), meta: map()}
end
