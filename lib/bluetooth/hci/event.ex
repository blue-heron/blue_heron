defmodule Bluetooth.HCI.Event do
  @callback deserialize(binary()) :: struct()

  alias Bluetooth.HCI.Event

  @modules [
    Event.CommandComplete,
    Event.CommandStatus,
    Event.DisconnectionComplete,
    Event.InquiryComplete,
    Event.LEMeta.AdvertisingReport,
    Event.LEMeta.ConnectionComplete
  ]

  def __modules__(), do: @modules
  def __indicator__(), do: 0x04

  defmacro defparameters(fields) do
    quote location: :keep, bind_quoted: [fields: fields] do
      fields =
        if Keyword.keyword?(fields) do
          fields
        else
          for key <- fields, do: {key, nil}
        end

      # This is odd, but defparameters/1 is only intended to be used
      # in modules with Bluetooth.HCI.Event.__using__/1 macro which will
      # @code defined. If not, let it fail
      fields = Keyword.merge(fields, code: @code)
      defstruct fields
    end
  end

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      code =
        Keyword.get_lazy(opts, :code, fn ->
          raise ":code key required when defining Bluetooth.HCI.Event.__using__/1"
        end)

      @behaviour Bluetooth.HCI.Event

      import Bluetooth.HCI.Event, only: [defparameters: 1]

      @code code

      def __code__(), do: @code
    end
  end
end
