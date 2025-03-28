# SPDX-FileCopyrightText: 2020 Connor Rigby
# SPDX-FileCopyrightText: 2023 Markus Hutzler
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Event do
  @moduledoc """
  Handles parsing of HCI Events (opcode 0x04).

  new event decoders should `use` this module, and be added to the
  `@modules` attribute.
  """

  @callback deserialize(binary()) :: struct()

  alias BlueHeron.HCI.Event

  @modules [
    Event.CommandComplete,
    Event.CommandStatus,
    Event.DisconnectionComplete,
    Event.EncryptionChange,
    Event.InquiryComplete,
    Event.LEMeta.AdvertisingReport,
    Event.LEMeta.ConnectionComplete,
    Event.LEMeta.ConnectionUpdateComplete,
    Event.LEMeta.EnhancedConnectionCompleteV1,
    Event.LEMeta.LongTermKeyRequest,
    Event.NumberOfCompletedPackets
  ]

  @doc "returns the list of parsable modules"
  def __modules__(), do: @modules

  @doc "returns the opcode for HCI Events"
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
      # in modules with BlueHeron.HCI.Event.__using__/1 macro which will
      # @code defined. If not, let it fail
      fields = Keyword.merge(fields, code: @code)
      defstruct fields
    end
  end

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      code =
        Keyword.get_lazy(opts, :code, fn ->
          raise ":code key required when defining BlueHeron.HCI.Event.__using__/1"
        end)

      @behaviour BlueHeron.HCI.Event

      import BlueHeron.HCI.Event, only: [defparameters: 1]

      @code code

      def __code__(), do: @code
    end
  end
end
