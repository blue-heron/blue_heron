defmodule BlueHeron.ATT.FindByTypeValueResponse do
  @moduledoc """
  > The ATT_FIND_BY_TYPE_VALUE_RSP PDU is sent in reply to a received
  > ATT_FIND_BY_TYPE_VALUE_REQ PDU and contains information about this server.

  Bluetooth Spec v5.2, vol 3, Part F, 3.4.3.4
  """

  defstruct [:opcode, :handles_information_list]

  defmodule HandlesInformation do
    @moduledoc """
    Strucutured HandleInformation encoder/decoder.
    """

    defstruct [:found_attribute_handle, :group_end_handle]

    def serialize(%{
          found_attribute_handle: found_attribute_handle,
          group_end_handle: group_end_handle
        }) do
      <<found_attribute_handle::little-16, group_end_handle::little-16>>
    end

    def deserialize(<<found_attribute_handle::little-16, group_end_handle::little-16>>) do
      %__MODULE__{
        found_attribute_handle: found_attribute_handle,
        group_end_handle: group_end_handle
      }
    end
  end

  def serialize(%{handles_information_list: handles_information_list}) do
    handles_information_list =
      handles_information_list
      |> Enum.map(fn handles_info -> HandlesInformation.serialize(handles_info) end)
      |> IO.iodata_to_binary()

    <<0x07, handles_information_list::binary>>
  end

  def deserialize(<<0x07, handles_information_list::binary>>) do
    handles_information_list =
      for <<handles_info::binary-4 <- handles_information_list>> do
        HandlesInformation.deserialize(handles_info)
      end

    %__MODULE__{opcode: 0x07, handles_information_list: handles_information_list}
  end
end
