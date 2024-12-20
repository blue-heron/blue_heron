defmodule BlueHeron.HCI.Command.ControllerAndBaseband do
  @moduledoc """
  HCI commands for working with the controller and baseband.

  * OGF: `#{inspect(@ogf, base: :hex)}`

  > The Controller & Baseband Commands provide access and control to various capabilities of the
  > Bluetooth hardware. These parameters provide control of BR/EDR Controllers and of the
  > capabilities of the Link Manager and Baseband in the BR/EDR Controller, the PAL in an AMP
  > Controller, and the Link Layer in an LE Controller. The Host can use these commands to modify
  > the behavior of the local Controller.
  Bluetooth Spec v5
  """

  alias __MODULE__, as: CaB
  @ogf 0x03

  @doc false
  def __ogf__(), do: @ogf

  @doc """
  List all available controller and baseband command modules
  """
  @spec list :: [module()]
  def list() do
    Application.spec(:blue_heron, :modules)
    |> Enum.filter(
      &match?(["BlueHeron", "HCI", "Command", "ControllerAndBaseband", _mod], Module.split(&1))
    )
  end

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      ocf =
        Keyword.get_lazy(opts, :ocf, fn ->
          raise ":ocf key required when defining HCI.Command.ControllerAndBaseband.__using__/1"
        end)

      use BlueHeron.HCI.Command, Keyword.put(opts, :ogf, CaB.__ogf__())

      @ocf ocf
      @opcode BlueHeron.HCI.Command.opcode(CaB.__ogf__(), @ocf)

      def __ocf__(), do: @ocf
      def __opcode__(), do: @opcode
    end
  end
end
