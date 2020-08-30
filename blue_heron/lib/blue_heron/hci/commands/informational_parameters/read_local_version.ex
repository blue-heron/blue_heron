defmodule BlueHeron.HCI.Command.InformationalParameters.ReadLocalVersion do
  @behaviour BlueHeron.HCI.Command
  defstruct []

  @impl BlueHeron.HCI.Command
  def opcode, do: 0xC14

  @impl BlueHeron.HCI.Command
  def serialize(%__MODULE__{}), do: ""

  @impl BlueHeron.HCI.Command
  def deserialize(_), do: %__MODULE__{}

  @impl BlueHeron.HCI.Command
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
      status_name: BlueHeron.ErrorCode.name!(status),
      hci_version: hci_version,
      hci_revision: hci_revision,
      lmp_pal_version: lmp_pal_version,
      manufacturer_name: manufacturer_name,
      lmp_pal_subversion: lmp_pal_subversion
    }
  end

  @impl BlueHeron.HCI.Command
  def serialize_return_parameters(%{status: status} = params) do
    <<status::8, params.hci_version::8, params.hci_revision::little-16, params.lmp_pal_version::8,
      params.manufacturer_name::little-16, params.lmp_pal_subversion::little-16>>
  end
end
