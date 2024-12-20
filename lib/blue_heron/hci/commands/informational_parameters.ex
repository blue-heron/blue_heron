defmodule BlueHeron.HCI.Command.InformationalParameters do
  @moduledoc """
  HCI commands for working with the informational parameters.

  * OGF: `#{inspect(@ogf, base: :hex)}`

  The Informational Parameters are fixed by the manufacturer of the Bluetooth
  hardware. These parameters provide information about the BR/EDR Controller and
  the capabilities of the Link Manager and Baseband in the BR/EDR Controller and
  PAL in the AMP Controller. The host device cannot modify any of these
  parameters.

  Bluetooth Spec v5.2, vol 4, Part E, 7.2
  """

  alias __MODULE__, as: IP
  @ogf 0x04

  @doc false
  def __ogf__(), do: @ogf

  @doc """
  List all available controller and baseband command modules
  """
  @spec list :: [module()]
  def list() do
    Application.spec(:blue_heron, :modules)
    |> Enum.filter(
      &match?(["BlueHeron", "HCI", "Command", "InformationalParameters", _mod], Module.split(&1))
    )
  end

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      ocf =
        Keyword.get_lazy(opts, :ocf, fn ->
          raise ":ocf key required when defining HCI.Command.InformationalParameters.__using__/1"
        end)

      use BlueHeron.HCI.Command, Keyword.put(opts, :ogf, IP.__ogf__())

      @ocf ocf
      @opcode BlueHeron.HCI.Command.opcode(IP.__ogf__(), @ocf)

      def __ocf__(), do: @ocf
      def __opcode__(), do: @opcode
    end
  end
end
