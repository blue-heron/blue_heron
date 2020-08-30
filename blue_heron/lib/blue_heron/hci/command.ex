defmodule BlueHeron.HCI.Command do
  # 16 bit integer
  @type opcode() :: 0x00..0xFFFF

  @type ogf :: 0..1023
  @type ocf :: 0..63

  @callback opcode() :: opcode()
  @callback deserialize(binary()) :: struct() | binary()
  @callback serialize(struct()) :: binary()
  @callback deserialize_return_parameters(binary() | map()) :: binary()
  @callback serialize_return_parameters(map()) :: binary()
  @optional_callbacks [serialize_return_parameters: 1, deserialize_return_parameters: 1]

  alias BlueHeron.HCI.Command.{
    LinkPolicy.WriteDefaultLinkPolicySettings
  }

  alias BlueHeron.HCI.Command.{
    ControllerAndBaseband.ReadLocalName,
    ControllerAndBaseband.Reset,
    ControllerAndBaseband.SetEventMask,
    ControllerAndBaseband.WriteClassOfDevice,
    ControllerAndBaseband.WriteExtendedInquiryResponse,
    ControllerAndBaseband.WriteInquiryMode,
    ControllerAndBaseband.WriteLocalName,
    ControllerAndBaseband.WritePageTimeout,
    ControllerAndBaseband.WriteSecureConnectionsHostSupport,
    ControllerAndBaseband.WriteSimplePairingMode
  }

  alias BlueHeron.HCI.Command.{
    InformationalParameters.ReadLocalVersion
  }

  alias BlueHeron.HCI.Command.{
    LEController.CreateConnection,
    LEController.SetScanEnable
  }

  defstruct [:opcode, :ogf, :ocf, :data]

  def deserialize(<<opcode::little-16, data_len, data::binary-size(data_len)>>) do
    <<ogf::6, ocf::10>> = <<opcode::16>>

    command = %__MODULE__{
      opcode: opcode,
      ogf: ogf,
      ocf: ocf,
      data: data
    }

    if type = implementation_for(ogf, ocf) do
      %{command | data: type.deserialize(data)}
    else
      command
    end
  end

  def serialize(%__MODULE__{data: %type{} = data} = command) do
    serialize(%__MODULE__{command | data: type.serialize(data)})
  end

  def serialize(%__MODULE__{opcode: opcode, data: data}) when is_binary(data) do
    data_len = byte_size(data)
    <<opcode::little-16, data_len, data::binary-size(data_len)>>
  end

  # don't force users to wrap the command themself
  def serialize(%type{} = command) do
    serialize(%__MODULE__{opcode: type.opcode, data: command})
  end

  # already serialized
  def serialize(<<_::little-16, data_len, _::binary-size(data_len)>> = command), do: command

  @doc "Get a module implementation for an opcode or ogf/ocf combo"
  @spec implementation_for(opcode) :: module() | nil
  @spec implementation_for(ogf, ocf) :: module() | nil
  def implementation_for(opcode) do
    <<ogf::6, ocf::10>> = <<opcode::16>>
    implementation_for(ogf, ocf)
  end

  # LinkPolicy
  def implementation_for(0x2, 0x0F), do: WriteDefaultLinkPolicySettings

  # ControllerAndBaseband
  def implementation_for(0x3, 0x01), do: SetEventMask
  def implementation_for(0x3, 0x03), do: Reset
  def implementation_for(0x3, 0x13), do: WriteLocalName
  def implementation_for(0x3, 0x14), do: ReadLocalName
  def implementation_for(0x3, 0x18), do: WritePageTimeout
  def implementation_for(0x3, 0x24), do: WriteClassOfDevice
  def implementation_for(0x3, 0x45), do: WriteInquiryMode
  def implementation_for(0x3, 0x52), do: WriteExtendedInquiryResponse
  def implementation_for(0x3, 0x56), do: WriteSimplePairingMode
  def implementation_for(0x3, 0x71), do: WriteSecureConnectionsHostSupport

  # InformationalParameters
  def implementation_for(0x4, 0x01), do: ReadLocalVersion

  # LEController
  def implementation_for(0x8, 0x0C), do: SetScanEnable
  def implementation_for(0x8, 0x0D), do: CreateConnection

  # fallback
  def implementation_for(_, _), do: nil
end
