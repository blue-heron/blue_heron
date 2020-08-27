defmodule Bluetooth.HCI.Command.InformationalParameters.ReadLocalVersion do
  use Bluetooth.HCI.Command.InformationalParameters, ocf: 0x0001

  alias Bluetooth.ErrorCode, as: Status

  defparameters []

  defimpl Bluetooth.HCI.Serializable do
    def serialize(rlv) do
      <<rlv.opcode::binary, 0>>
    end
  end

  @impl Bluetooth.HCI.Command
  def deserialize(<<@opcode::binary, 0, "">>) do
    %__MODULE__{}
  end

  @impl Bluetooth.HCI.Command
  def deserialize_return_parameters(<<status::8, bin::binary>>) do
    <<
      hci_version,
      hci_revision::little-16,
      lmp_pal_version,
      manufacturer_name::little-16,
      lmp_pal_subversion::little-16
    >> = bin

    %{
      status: status,
      status_name: Status.name!(status),
      hci_version: hci_version,
      hci_revision: hci_revision,
      lmp_pal_version: lmp_pal_version,
      manufacturer_name: manufacturer_name,
      lmp_pal_subversion: lmp_pal_subversion
    }
  end

  @impl Bluetooth.HCI.Command
  def serialize_return_parameters(%{status: status} = params) do
    <<status::8, params.hci_version::8, params.hci_revision::little-16, params.lmp_pal_version::8,
      params.manufacturer_name::little-16, params.lmp_pal_subversion::little-16>>
  end
end
