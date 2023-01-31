# MIT License

# Copyright (c) 2019 Very

# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:

# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.

# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
defmodule BlueHeron.HCI.Event do
  @callback deserialize(binary()) :: struct()

  alias BlueHeron.HCI.Event

  @modules [
    Event.EncryptionChange,
    Event.CommandComplete,
    Event.CommandStatus,
    Event.NumberOfCompletedPackets,
    Event.DisconnectionComplete,
    Event.InquiryComplete,
    Event.LEMeta.AdvertisingReport,
    Event.LEMeta.ConnectionComplete,
    Event.LEMeta.LongTermKeyRequest
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
