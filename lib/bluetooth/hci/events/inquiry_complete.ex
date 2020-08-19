defmodule Bluetooth.HCI.Event.InquiryComplete do
  use Bluetooth.HCI.Event, code: 0x01

  @moduledoc """
  > The Inquiry Complete event indicates that the Inquiry is finished. This event contains a
  > Status parameter, which is used to indicate if the Inquiry completed successfully or if the
  > Inquiry was not completed.

  Reference: Version 5.2, Vol 4, Part E, 7.7.1
  """

  alias Bluetooth.ErrorCode

  defparameters [:status, :status_name]

  defimpl Bluetooth.HCI.Serializable do
    def serialize(data) do
      <<data.code, 1, data.status>>
    end
  end

  @impl Bluetooth.HCI.Event
  def deserialize(<<@code, _size, status>>) do
    %__MODULE__{
      status: status,
      status_name: ErrorCode.name!(status)
    }
  end

  def deserialize(bin), do: {:error, bin}
end
