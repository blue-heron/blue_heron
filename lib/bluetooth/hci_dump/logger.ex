defmodule Bluetooth.HCIDump.Logger do
  @moduledoc """
  Wrapper around Elixir's Logger to facilitate HCI Logging.

  Usage:

      iex> require Bluetooth.HCIDump.Logger, as: Logger
      Bluetooth.HCIDump.Logger

      iex> Logger.debug "hey"
      :ok

      16:05:03.577 [debug] hey

      iex> Bluetooth.HCIDump.decode_file!("/tmp/hcidump.pklg")
      [%Bluetooth.HCIDump.PKTLOG{payload: "hey", tv_sec: 1597075503, tv_us: 577, type: :LOG_MESSAGE_PACKET}]

  """

  alias Bluetooth.{HCIDump, HCIDump.PKTLOG}
  @behaviour :gen_event

  @doc "See `Elixir.Logger.info/2`"
  defmacro info(chardata_or_fun, metadata \\ []) do
    quote location: :keep do
      require Logger

      metadata = [
        {:pktlog_direction, :out},
        {:pktlog, %PKTLOG{type: :LOG_MESSAGE_PACKET, payload: unquote(chardata_or_fun)}}
        | unquote(metadata)
      ]

      :ok = Logger.log(:info, unquote(chardata_or_fun), metadata)
    end
  end

  @doc "See `Elixir.Logger.debug/2`"
  defmacro debug(chardata_or_fun, metadata \\ []) do
    quote location: :keep do
      require Logger

      metadata = [
        {:pktlog_direction, :out},
        {:pktlog, %PKTLOG{type: :LOG_MESSAGE_PACKET, payload: unquote(chardata_or_fun)}}
        | unquote(metadata)
      ]

      :ok = Logger.log(:debug, unquote(chardata_or_fun), metadata)
    end
  end

  @doc "See `Elixir.Logger.warn/2`"
  defmacro warn(chardata_or_fun, metadata \\ []) do
    quote location: :keep do
      require Logger

      metadata = [
        {:pktlog_direction, :out},
        {:pktlog, %PKTLOG{type: :LOG_MESSAGE_PACKET, payload: unquote(chardata_or_fun)}}
        | unquote(metadata)
      ]

      :ok = Logger.log(:warn, unquote(chardata_or_fun), metadata)
    end
  end

  @doc "See `Elixir.Logger.error/2`"
  defmacro error(chardata_or_fun, metadata \\ []) do
    quote location: :keep do
      require Logger

      metadata = [
        {:pktlog_direction, :out},
        {:pktlog, %PKTLOG{type: :LOG_MESSAGE_PACKET, payload: unquote(chardata_or_fun)}}
        | unquote(metadata)
      ]

      :ok = Logger.log(:error, unquote(chardata_or_fun), metadata)
    end
  end

  @doc """
  HCI Packet Logger
  `type` must be one of

      :HCI_COMMAND_DATA_PACKET,
      :HCI_ACL_DATA_PACKET,
      :HCI_SCO_DATA_PACKET,
      :HCI_EVENT_PACKET,
      :LOG_MESSAGE_PACKET

  `direction` must be one of

      :in,
      :out

  `payload` must be a binary.
  `metadata` is optional metadata to pass through to Elixir.Logger
  """
  defmacro hci_packet(type, direction, payload, _metadata \\ [])
           when type in [
                  :HCI_COMMAND_DATA_PACKET,
                  :HCI_ACL_DATA_PACKET,
                  :HCI_SCO_DATA_PACKET,
                  :HCI_EVENT_PACKET,
                  :LOG_MESSAGE_PACKET
                ] and direction in [:in, :out] do
    quote location: :keep do
      require Logger
      ts = DateTime.utc_now() |> DateTime.to_unix(:second)
      usec = 0
      pktlog = %PKTLOG{type: unquote(type), payload: unquote(payload)}
      encoded = HCIDump.encode(%PKTLOG{pktlog | tv_sec: ts, tv_us: usec}, unquote(direction))

      File.write("/tmp/hcidump.pklg", encoded, [:append])

      # metadata = [
      #   {:pktlog_direction, unquote(direction)},
      #   {:pktlog, %PKTLOG{type: unquote(type), payload: unquote(payload)}} | unquote(metadata)
      # ]

      # :ok =
      #   Logger.log(
      #     :debug,
      #     ["HCI Packet #{unquote(direction)}", " ", inspect(unquote(payload), base: :hex)],
      #     metadata
      #   )
    end
  end

  #
  # Logger backend callbacks
  #
  @impl :gen_event
  def init(__MODULE__) do
    init({__MODULE__, []})
  end

  @impl :gen_event
  def init({__MODULE__, opts}) when is_list(opts) do
    env = Application.get_env(:logger, __MODULE__, [])
    opts = Keyword.merge(env, opts)
    Application.put_env(:logger, __MODULE__, opts)
    {:ok, configure(opts)}
  end

  @impl :gen_event
  def handle_call({:configure, opts}, _state) do
    env = Application.get_env(:logger, __MODULE__, [])
    opts = Keyword.merge(env, opts)
    Application.put_env(:logger, __MODULE__, opts)
    {:ok, :ok, configure(opts)}
  end

  @impl :gen_event
  def handle_event({_level, _group_leader, {_mod, msg, ts, md}}, state) do
    {{year, month, day}, {hour, minute, second, usec}} = ts

    ts =
      %DateTime{
        year: year,
        month: month,
        day: day,
        hour: hour,
        minute: minute,
        second: second,
        time_zone: "Etc/UTC",
        zone_abbr: "UTC",
        std_offset: 0,
        utc_offset: 0
      }
      |> DateTime.to_unix(:second)

    encoded =
      case md[:pktlog] do
        %PKTLOG{type: :LOG_MESSAGE_PACKET} = pktlog ->
          dir = md[:pktlog_direction]
          # payload = IO.iodata_to_binary([md[:file], ":", md[:line], " ", msg])
          payload = IO.iodata_to_binary(msg)
          HCIDump.encode(%PKTLOG{pktlog | tv_sec: ts, tv_us: usec, payload: payload}, dir)

        %PKTLOG{} = pktlog ->
          dir = md[:pktlog_direction]
          HCIDump.encode(%PKTLOG{pktlog | tv_sec: ts, tv_us: usec}, dir)

        nil ->
          nil
      end

    if encoded, do: File.write(state[:logfile], encoded, [:append])

    {:ok, state}
  end

  # flush not needed
  def handle_event(:flush, state) do
    {:ok, state}
  end

  @impl :gen_event
  def handle_info(_, state) do
    # Ignore everything else
    {:ok, state}
  end

  @impl :gen_event
  def code_change(_old_vsn, state, _extra) do
    {:ok, state}
  end

  @impl :gen_event
  def terminate(_reason, _state) do
    :ok
  end

  defp configure(opts), do: Keyword.put_new(opts, :logfile, "/tmp/hcidump.pklg")
end
