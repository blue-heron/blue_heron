defmodule BlueHeron.HCI.Command.InformationalParameters.ReadLocalVersion do
  use BlueHeron.HCI.Command.InformationalParameters, ocf: 0x0001

  alias BlueHeron.ErrorCode, as: Status

  defparameters []

  defimpl BlueHeron.HCI.Serializable do
    def serialize(rlv) do
      <<rlv.opcode::binary, 0>>
    end
  end

  @impl BlueHeron.HCI.Command
  def deserialize(<<@opcode::binary, 0>>) do
    %__MODULE__{}
  end

  @impl BlueHeron.HCI.Command
  def deserialize_return_parameters(<<status, bin::binary>>) do
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

  @impl BlueHeron.HCI.Command
  def serialize_return_parameters(%{status: status} = params) do
    <<status, params.hci_version, params.hci_revision::little-16, params.lmp_pal_version,
      params.manufacturer_name::little-16, params.lmp_pal_subversion::little-16>>
  end
end
