defmodule BlueHeron.HCI.Command.LinkControl do
  alias __MODULE__, as: LC
  @ogf 0x01

  def __ogf__(), do: @ogf

  @doc """
  List all available LE Controller command modules
  """
  @spec list :: [module()]
  def list() do
    Application.spec(:blue_heron, :modules)
    |> Enum.filter(
      &match?(["BlueHeron", "HCI", "Command", "LinkControl", _mod], Module.split(&1))
    )
  end

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      ocf =
        Keyword.get_lazy(opts, :ocf, fn ->
          raise ":ocf key required when defining HCI.Command.LinkControl.__using__/1"
        end)

      use BlueHeron.HCI.Command, Keyword.put(opts, :ogf, LC.__ogf__())

      @ocf ocf
      @opcode BlueHeron.HCI.Command.opcode(LC.__ogf__(), @ocf)

      def __ocf__(), do: @ocf
      def __opcode__(), do: @opcode
    end
  end
end
