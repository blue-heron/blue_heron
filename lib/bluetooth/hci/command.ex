defmodule Bluetooth.HCI.Command do
  @callback return_parameters(binary()) :: map() | binary()
  @callback deserialize(binary()) :: term()

  alias __MODULE__.{ControllerAndBaseband, LEController}

  @modules [
    ControllerAndBaseband.ReadLocalName,
    ControllerAndBaseband.Reset,
    ControllerAndBaseband.SetEventMask,
    ControllerAndBaseband.WriteClassOfDevice,
    ControllerAndBaseband.WriteExtendedInquiryResponse,
    ControllerAndBaseband.WriteLocalName,
    ControllerAndBaseband.WritePageTimeout,
    ControllerAndBaseband.WriteSimplePairingMode,
    LEController.CreateConnection,
    LEController.SetScanEnable
  ]

  def __modules__(), do: @modules

  @doc """
  Helper to create Command opcode from OCF and OGF values
  """
  def opcode(ogf, ocf) when ogf < 64 and ocf < 1024 do
    <<opcode::16>> = <<ogf::6, ocf::10>>
    <<opcode::little-16>>
  end

  defmacro defparameters(fields) do
    quote location: :keep, bind_quoted: [fields: fields] do
      fields =
        if Keyword.keyword?(fields) do
          fields
        else
          for key <- fields, do: {key, nil}
        end

      # This is odd, but defparameters/1 is only intended to be used
      # in modules with Bluetooth.HCI.Command.__using__/1 macro which will
      # have these attributes defined. If not, let it fail
      fields = Keyword.merge(fields, ogf: @ogf, ocf: @ocf, opcode: @opcode)
      defstruct fields
    end
  end

  defmacro __using__(opts) do
    quote location: :keep, bind_quoted: [opts: opts] do
      ogf =
        Keyword.get_lazy(opts, :ogf, fn ->
          raise ":ogf key required when defining HCI.Command.__using__/1"
        end)

      @behaviour Bluetooth.HCI.Command
      import Bluetooth.HCI.Command, only: [defparameters: 1]

      @ogf ogf

      def __ogf__(), do: @ogf

      def new(args \\ []), do: struct(__MODULE__, args)
    end
  end
end
