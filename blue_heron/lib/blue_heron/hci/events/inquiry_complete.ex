defmodule BlueHeron.HCI.Event.InquiryComplete do
  @moduledoc """
  > The Inquiry Complete event indicates that the Inquiry is finished. This event contains a
  > Status parameter, which is used to indicate if the Inquiry completed successfully or if the
  > Inquiry was not completed.

  Reference: Version 5.2, Vol 4, Part E, 7.7.1
  """

  @behaviour BlueHeron.HCI.Event

  defstruct [:status, :status_name]

  @impl BlueHeron.HCI.Event
  def serialize(data) do
    <<data.status>>
  end

  @impl BlueHeron.HCI.Event
  def deserialize(<<status>>) do
    %__MODULE__{
      status: status,
      status_name: BlueHeron.ErrorCode.name!(status)
    }
  end
end
