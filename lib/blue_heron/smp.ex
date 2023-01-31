defmodule BlueHeron.SMP do
  @moduledoc """
  A behaviour module for implementing BLE Security Manager Protocol.
  """

  use GenServer

  require Logger

  alias BlueHeron.HCI.Command.LEController.LongTermKeyRequestReply
  alias BlueHeron.{ACL, L2Cap}
  alias BlueHeron.SMP.Keys

  defstruct [
    :ctx,
    :pres,
    :preq,
    :k,
    :ir,
    :r,
    :confirm,
    :stk,
    :ltk,
    :bd_address,
    :connection,
    :authenticated,
    :keys
  ]

  @doc false
  def start_link(ctx, keyfile) do
    GenServer.start_link(__MODULE__, [ctx, keyfile], name: __MODULE__)
  end

  @doc false
  @impl GenServer
  def init(ctx, keyfile) do
    # TODO: Use specific file path
    Elixir.BlueHeron.SMP.Keys.start(keyfile)
    {:ok, %__MODULE__{ctx: ctx, authenticated: false}}
  end

  @doc "Set BR_ADDR."
  def set_bd_address(addr) do
    GenServer.cast(__MODULE__, {:set_bd_address, addr})
  end

  @doc """
  Returns true if the current connection is authenticated.
  """
  def is_authenticated?() do
    GenServer.call(__MODULE__, :is_authenticated)
  end

  @doc """
  Set connection information.

  The information is needed for key generation.
  """
  def set_connection(con) do
    GenServer.cast(__MODULE__, {:set_connection, con})
  end

  @doc """
  Handle Long Term Key Request event.

  This function returns a Long Term Key Request Response or nil.
  """
  def long_term_key_request(msg) do
    GenServer.call(__MODULE__, {:long_term_key_request, msg})
  end

  @doc """
  Inform the Security Manager about changes in the encryption.
  """
  def encryption_change(event) do
    GenServer.call(__MODULE__, {:encryption_change, event})
  end

  def handle(msg) do
    GenServer.call(__MODULE__, {:handle, msg})
  end

  @impl GenServer
  def handle_cast({:set_bd_address, addr}, state) do
    {:noreply, %{state | bd_address: addr}}
  end

  def handle_cast({:set_connection, con}, state) do
    {:noreply, %{state | connection: con, authenticated: false}}
  end

  @impl GenServer
  def handle_call(:is_authenticated, _from, state) do
    {:reply, state.authenticated, state}
  end

  def handle_call({:handle, <<0x01, data::binary>>}, _from, state) do
    # Pairing Request
    Logger.info("Handle Pairing Request")
    <<_io, _obb, _auth, max_key, _idist, _rdist>> = data
    Logger.info("DATA: #{Base.encode16(data)}")
    Logger.info("Max key Size: #{max_key}")

    passkey = :rand.uniform(999_999)

    message =
      passkey
      |> Integer.to_string()
      |> String.pad_leading(6, "0")

    # TODO: inform caller to show passkey on display # callback(random)
    # callback: pairing({status: :progress, passkey: message})
    Logger.info("Key distribution flags: #{Base}")

    Logger.info("=================== #{message} ===================")

    k = <<passkey::integer-size(128)>>
    r = :crypto.strong_rand_bytes(16)
    response = <<0x02, 0x01, 0x00, 0b00000101, 16, 0x0F, 0x0F>>

    state = %{
      state
      | pres: response,
        preq: <<0x01>> <> data,
        k: k,
        ir: nil,
        r: r,
        confirm: nil,
        stk: nil,
        ltk: nil,
        authenticated: false
    }

    {:reply, response, state}
  end

  def handle_call({:handle, <<0x02, _data::binary>>}, _from, state) do
    # Pairing Response
    Logger.info("Handle Pairing Response")
    response = nil
    {:reply, response, state}
  end

  def handle_call({:handle, <<0x03, confirm::binary>>}, _from, state) do
    Logger.info("Handle Pairing Confirm")
    preq = reverse(state.preq)
    pres = reverse(state.pres)
    k = state.k
    r = state.r

    ia = BlueHeron.Address.parse(state.connection.peer_address).binary()
    iat = state.connection.peer_address_type
    ra = state.bd_address.binary()
    rat = 0

    Logger.info("k=#{inspect(k)}, r=#{inspect(r)}, preq=#{inspect(preq)},
      pres=#{inspect(pres)}, iat=#{inspect(iat)}, rat=#{inspect(rat)},
      ia=#{inspect(ia)}, ra=#{inspect(ra)}")
    response = c1(k, r, preq, pres, iat, rat, ia, ra)
    {:reply, <<0x03>> <> reverse(response), %{state | confirm: reverse(confirm)}}
  end

  def handle_call({:handle, <<0x04, random::binary>>}, _from, state) do
    Logger.info("Handle Pairing Random")

    # Use c1() with peer random
    preq = reverse(state.preq)
    pres = reverse(state.pres)
    k = state.k
    r = reverse(random)
    ia = BlueHeron.Address.parse(state.connection.peer_address).binary()
    iat = state.connection.peer_address_type
    ra = state.bd_address.binary()
    rat = 0

    Logger.info("k=#{inspect(k)}, r=#{inspect(r)}, preq=#{inspect(preq)},
      pres=#{inspect(pres)}, iat=#{inspect(iat)}, rat=#{inspect(rat)},
      ia=#{inspect(ia)}, ra=#{inspect(ra)}")

    response = c1(k, r, preq, pres, iat, rat, ia, ra)

    # Is confirmed?
    Logger.debug("response = #{Base.encode16(response)}")
    Logger.debug("confirm = #{Base.encode16(state.confirm)}")

    if state.confirm == response do
      # TODO: inform caller that pairing completed
      # callback: pairing({status: :success})
      {:reply, <<0x04>> <> reverse(state.r), %{state | ir: r}}
    else
      Logger.debug("PASSKEY MISSMATCH")
      # Return passkey missmatch
      state = %{
        preq: nil,
        pres: nil,
        k: nil,
        ir: nil,
        r: nil,
        confirm: nil,
        stk: nil,
        ltk: nil
      }

      # TODO: inform caller that pairing failed
      # callback: pairing({status: :failed})

      {:reply, <<0x05, 0x04>>, state}
    end
  end

  def handle_call({:handle, <<0x05, reason>>}, _from, state) do
    Logger.info("Handle Pairing Failed")
    Logger.warn("Pairing failed: #{reason}")
    # TODO: inform caller that pairing failed
    # callback: pairing({status: :failed})
    {:reply, nil, state}
  end

  def handle_call({:handle, <<0x06, ltk::binary>>}, _from, state) do
    Logger.debug("GOT LTK: #{Base.encode16(reverse(ltk))})")
    {:reply, nil, state}
  end

  def handle_call(
        {:handle, <<0x07, ediv::little-unsigned-16, rand::little-unsigned-64>>},
        _from,
        state
      ) do
    Logger.debug("GOT EDIV #{ediv} and RAND #{rand})")
    {:reply, nil, state}
  end

  def handle_call({:handle, <<0x0A, csrk::binary>>}, _from, state) do
    Logger.debug("GOT CSRK: #{Base.encode16(reverse(csrk))})")
    {:reply, nil, state}
  end

  def handle_call({:handle, msg}, _from, state) do
    Logger.warning("Unknown SMP request: #{inspect(msg)}")
    {:reply, nil, state}
  end

  def handle_call({:long_term_key_request, %{encrypted_diversifier: 0} = request}, _from, state) do
    Logger.warn("Build LTK and respond for #{inspect(request)} (Without EDIV)")

    stk = s1(state.k, state.r, state.ir)

    command =
      LongTermKeyRequestReply.new(
        connection_handle: request.connection_handle,
        ltk: reverse(stk)
      )

    {:reply, command, %{state | stk: stk}}
  end

  def handle_call({:long_term_key_request, request}, _from, state) do
    Logger.warn("Build LTK and respond for #{inspect(request)} (with EDIV)")

    # TODO: Handle unknown EDIV
    {ediv,
     <<
       rand::bytes-size(8),
       ltk::bytes-size(16),
       csrk::bytes-size(16),
       irk::bytes-size(16)
     >>} = Keys.get(request.encrypted_diversifier)

    command =
      LongTermKeyRequestReply.new(
        connection_handle: request.connection_handle,
        ltk: reverse(ltk)
      )

    {:reply, command, state}
  end

  def handle_call({:encryption_change, event}, _from, state) do
    # We got an encrypted channel, lets exchange keys

    # We are using the DATABASE LOOKUP described in the Bluetooth pecification
    # Version 5.3 | Vol 3, Part H Appendix B1
    {ediv,
     <<
       rand::bytes-size(8),
       ltk::bytes-size(16),
       csrk::bytes-size(16),
       irk::bytes-size(16)
     >>} = Keys.new()

    Logger.debug("LTK: #{Base.encode16(ltk)}")
    Logger.debug("CSRK: #{Base.encode16(csrk)}")
    Logger.debug("IRK: #{Base.encode16(irk)}")
    Logger.debug("EDIV: #{ediv}")

    # generate and send LTK using "Encryption Information" ACL message
    frame = acl(event.connection_handle, <<0x06>> <> reverse(ltk))
    BlueHeron.acl(state.ctx, frame)
    :timer.sleep(200)

    # generate and send EDIV and RAND using "Central Identification" ACL message
    frame = acl(event.connection_handle, <<0x07, ediv::little-unsigned-16>> <> reverse(rand))
    BlueHeron.acl(state.ctx, frame)
    :timer.sleep(200)

    # generate and send IRK using "Identity Information" ACL message
    frame = acl(event.connection_handle, <<0x08>> <> reverse(irk))
    BlueHeron.acl(state.ctx, frame)
    :timer.sleep(200)

    # generate and send BD_ADDRESS using "Identity Address Information" ACL message
    frame = acl(event.connection_handle, <<0x09, 0>> <> reverse(state.bd_address.binary()))
    BlueHeron.acl(state.ctx, frame)
    :timer.sleep(200)

    # generate and send CSRK using "Signing Information" ACL message
    frame = acl(event.connection_handle, <<0x0A>> <> reverse(csrk))
    BlueHeron.acl(state.ctx, frame)
    :timer.sleep(200)

    {:reply, nil, %{state | authenticated: true}}
  end

  @doc """
  Bluetooth LE c1() key generation function.

  The function parameters can be encoded by the following example:

  k is the random generated TK displayed on the device
  r is the random number generated by the SM
  preq is the data exchanged during pairing request
  pres is the data exchanged during pairing response
  iat is the initaitors device type (0x00 or 0x01)
  rat is the receiver device type (0x00 or 0x01)
  ia is the initaitors device address
  ra is the receiver device address

  Example from BLE specifications:

  k = <<0::integer-size(128)>>
  r = <<0x57, 0x83, 0xD5, 0x21, 0x56, 0xAD, 0x6F, 0x0E, 0x63, 0x88, 0x27, 0x4E, 0xC6, 0x70, 0x2E, 0xE0>>
  ia = <<0xA1, 0xA2, 0xA3, 0xA4, 0xA5, 0xA6>>
  ra = <<0xB1, 0xB2, 0xB3, 0xB4, 0xB5, 0xB6>>
  iat = 1
  rat = 0
  pres = <<0x05, 0x00, 0x08, 0x00, 0x00, 0x03, 0x02>>
  preq = <<0x07, 0x07, 0x10, 0x00, 0x00, 0x01, 0x01>>
  <<0x1E, 0x1E, 0x3F, 0xEF, 0x87, 0x89, 0x88, 0xEA, 0xD2, 0xA7, 0x4D, 0xC5, 0xBE, 0xF1, 0x3B, 0x86>> =
    BlueHeron.SMP.Server.c1(k, r, preq, pres, iat, rat, ia, ra)
  """
  def c1(k, r, preq, pres, iat, rat, ia, ra) do
    Logger.debug("DBG: c1() k: #{Base.encode16(k)}")
    Logger.debug("DBG: c1() r: #{Base.encode16(r)}")
    p1 = pres <> preq <> <<rat, iat>>
    p2 = <<0, 0, 0, 0>> <> ia <> ra
    res = :crypto.exor(r, p1)
    res = :crypto.crypto_one_time(:aes_128_ecb, k, res, true)
    res = :crypto.exor(res, p2)
    :crypto.crypto_one_time(:aes_128_ecb, k, res, true)
  end

  @doc """
  Diversifying function d1
  """
  def d1(k, d, r) do
    dx = <<0::integer-size(96), r::integer-size(16), d::integer-size(16)>>
    :crypto.crypto_one_time(:aes_128_ecb, k, dx, true)
  end

  @doc """
  Mask generation function dm
  """
  def dm(k, r) do
    rx = <<0::integer-size(64), r::bytes>>

    <<_::bytes-size(16), ret::bytes-size(16)>> =
      :crypto.crypto_one_time(:aes_128_ecb, k, rx, true)

    ret
  end

  @doc """
  Bluetooth LE s1() key generation function.

  k is the random generated TK displayed on the device
  r1 is the random generated by the responding device
  r2 is the random generated by the initiating device

  Example from BLE specifictation:

  k = <<0::integer-size(128)>>
  r1 = Base.decode16!("000F0E0D0C0B0A091122334455667788")
  r2 = Base.decode16!("010203040506070899AABBCCDDEEFF00")
  "9A1FE1F0E8B0F49B5B4216AE796DA062" = Base.encode16(BlueHeron.SMP.Server.s1(k, r1, r2))
  """
  def s1(k, r1, r2) do
    Logger.debug("DBG: s1() k: #{Base.encode16(k)}")
    Logger.debug("DBG: s1() r1: #{Base.encode16(r1)}")
    Logger.debug("DBG: s1() r2: #{Base.encode16(r2)}")
    <<_::binary-size(8), r1::binary-size(8)>> = r1
    <<_::binary-size(8), r2::binary-size(8)>> = r2
    r = r1 <> r2
    Logger.debug("DBG: s1() r: #{Base.encode16(r)}")
    :crypto.crypto_one_time(:aes_128_ecb, k, r, true)
  end

  @doc """
  Link key conversion function

  The function h6 is used to convert keys of a given size from one key type to
  another key type with equivalent strength.
  The definition of the h6 function makes use of the hashing function AES-
  CMAC W with 128-bit key W.

  Exmple test vectors from Bluetooth spec:

  w = Base.decode16!("EC0234A357C8AD05341010A60A397D9B")
  key_id = Base.decode16!("6C656272")  # ASCII "lebr"
  "2D9AE102E76DC91CE8D3A9E280B16399" = Base.encode16(BlueHeron.SMP.Server.h6(w, key_id)
  """
  def h6(w, key_id) do
    :crypto.mac(:cmac, :aes_cbc, w, key_id)
  end

  defp reverse(bin), do: bin |> :binary.decode_unsigned(:little) |> :binary.encode_unsigned(:big)

  defp acl(handle, data) do
    # Generate SMP related ACL response
    %ACL{
      handle: handle,
      flags: %{bc: 0, pb: 0},
      data: %L2Cap{
        cid: 0x0006,
        data: data
      }
    }
  end
end
