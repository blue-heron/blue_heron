defmodule BlueHeron.HCI.Event.InquiryComplete do
  use BlueHeron.HCI.Event, code: 0x01

  @moduledoc """
  > The Inquiry Complete event indicates that the Inquiry is finished. This event contains a
  > Status parameter, which is used to indicate if the Inquiry completed successfully or if the
  > Inquiry was not completed.

  Reference: Version 5.2, Vol 4, Part E, 7.7.1
  """

  defparameters [:status]

  defimpl BlueHeron.HCI.Serializable do
    def serialize(data) do
      <<data.code, 1, data.status>>
    end
  end

  @impl BlueHeron.HCI.Event
  def deserialize(<<@code, _size, status>>) do
    %__MODULE__{
      status: status
    }
  end

  def deserialize(bin), do: {:error, bin}
end
