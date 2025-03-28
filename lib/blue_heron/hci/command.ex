# SPDX-FileCopyrightText: 2020 Connor Rigby
# SPDX-FileCopyrightText: 2021 Troels Brødsgaard
# SPDX-FileCopyrightText: 2021 Jon Carstens
# SPDX-FileCopyrightText: 2023 Markus Hutzler
#
# SPDX-License-Identifier: Apache-2.0
#
defmodule BlueHeron.HCI.Command do
  @moduledoc """
  > The Link Control commands allow a Controller to control connections to other BR/EDR
  > Controllers. Some Link Control commands are used only with a BR/EDR Controller
  > whereas other Link Control commands are also used with an LE Controller.

  Bluetooth Spec v5.2, vol 4, Part E, 7
  """

  @callback deserialize_return_parameters(binary()) :: map() | binary()
  @callback serialize_return_parameters(map() | binary()) :: binary()
  @callback deserialize(binary()) :: term()

  alias __MODULE__.{ControllerAndBaseband, LEController, InformationalParameters, LinkPolicy}

  @modules [
    ControllerAndBaseband.ReadLocalName,
    ControllerAndBaseband.Reset,
    ControllerAndBaseband.SetEventMask,
    ControllerAndBaseband.WriteClassOfDevice,
    ControllerAndBaseband.WriteDefaultErroneousDataReporting,
    ControllerAndBaseband.WriteExtendedInquiryResponse,
    ControllerAndBaseband.WriteInquiryMode,
    ControllerAndBaseband.WriteLEHostSupport,
    ControllerAndBaseband.WriteLocalName,
    ControllerAndBaseband.WritePageTimeout,
    ControllerAndBaseband.WriteScanEnable,
    ControllerAndBaseband.WriteSecureConnectionsHostSupport,
    ControllerAndBaseband.WriteSimplePairingMode,
    ControllerAndBaseband.WriteSynchronousFlowControlEnable,
    InformationalParameters.ReadBdAddr,
    InformationalParameters.ReadBufferSize,
    InformationalParameters.ReadLocalSupportedCommands,
    InformationalParameters.ReadLocalVersion,
    LEController.CreateConnection,
    LEController.CreateConnectionCancel,
    LEController.ReadBufferSizeV1,
    LEController.ReadWhiteListSize,
    LEController.SetAdvertisingData,
    LEController.SetAdvertisingEnable,
    LEController.SetAdvertisingParameters,
    LEController.SetRandomAddress,
    LEController.SetScanEnable,
    LEController.SetScanResponseData,
    LEController.SetScanParameters,
    LEController.LongTermKeyRequestReply,
    LEController.LongTermKeyRequestNegativeReply,
    LinkPolicy.WriteDefaultLinkPolicySettings
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
      # in modules with BlueHeron.HCI.Command.__using__/1 macro which will
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

      @behaviour BlueHeron.HCI.Command
      import BlueHeron.HCI.Command, only: [defparameters: 1]

      @ogf ogf

      def __ogf__(), do: @ogf

      def new(args \\ []), do: struct(__MODULE__, args)
    end
  end
end
