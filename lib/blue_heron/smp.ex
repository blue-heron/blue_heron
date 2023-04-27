defmodule BlueHeron.SMP do
  @moduledoc """
  A behaviour module for implementing BLE Security Manager Protocol.
  """

  use GenServer

  require Logger

  alias BlueHeron.HCI.Command.LEController.{
    LongTermKeyRequestReply,
    LongTermKeyRequestNegativeReply
  }

  alias BlueHeron.{ACL, L2Cap}
  alias BlueHeron.SMP.KeyManager

  defstruct [
    :ctx,
    :pairing,
    :bd_address,
    :connection,
    :stk_used,
    :authenticated,
    :io_handler,
    :key_manager
  ]

  @doc false
  def start_link(ctx, io_handler) do
    GenServer.start_link(__MODULE__, [ctx, io_handler])
  end

  @doc false
  @impl GenServer
  def init([ctx, io_handler]) do
    with {:ok, keyfile} <- io_handler.keyfile(),
         {:ok, key_manager} <- KeyManager.start_link(keyfile) do
      {:ok,
       %__MODULE__{
         key_manager: key_manager,
         ctx: ctx,
         authenticated: false,
         io_handler: io_handler
       }}
    end
  end

  @doc "Set BR_ADDR."
  def set_bd_address(smp, addr) do
    GenServer.cast(smp, {:set_bd_address, addr})
  end

  @doc """
  Returns true if the current connection is authenticated.
  """
  def is_authenticated?(smp) do
    GenServer.call(smp, :is_authenticated)
  end

  @doc """
  Set connection information.

  The information is needed for key generation.
  """
  def set_connection(smp, con) do
    GenServer.cast(smp, {:set_connection, con})
  end

  @doc """
  Handle Long Term Key Request event.

  This function returns a Long Term Key Request Response or nil.
  """
  def long_term_key_request(smp, msg) do
    GenServer.call(smp, {:long_term_key_request, msg})
  end

  @doc """
  Inform the Security Manager about changes in the encryption.
  """
  def encryption_change(smp, event) do
    GenServer.call(smp, {:encryption_change, event})
  end

  def handle(smp, msg) do
    GenServer.call(smp, {:handle, msg})
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
    <<_io, _obb, _auth, _max_key, _idist, _rdist>> = data

    # TODO: Filter requests not matching parameters
    # Check max_key = 16

    passkey = :rand.uniform(999_999)

    message =
      passkey
      |> Integer.to_string()
      |> String.pad_leading(6, "0")

    _ = state.io_handler.status_update(:passkey)
    _ = state.io_handler.passkey(message)

    k = <<passkey::integer-size(128)>>
    r = :crypto.strong_rand_bytes(16)
    response = <<0x02, 0x01, 0x00, 0b00000101, 16, 0x0F, 0x0F>>

    # Set up all pairing related information
    pairing = %{
      pres: reverse(response),
      preq: reverse(<<0x01>> <> data),
      k: k,
      ir: nil,
      r: r,
      confirm: nil
    }

    {:reply, response, %{state | pairing: pairing, authenticated: false}}
  end

  def handle_call({:handle, <<0x02, _data::binary>>}, _from, state) do
    # Pairing Response
    Logger.warning("Ignoring Handle Pairing Response")
    {:reply, nil, state}
  end

  def handle_call({:handle, <<0x03, confirm::binary>>}, _from, state) do
    # Handle Pairing Confirm

    pairing = %{state.pairing | confirm: reverse(confirm)}
    ia = BlueHeron.Address.parse(state.connection.peer_address).binary()
    iat = state.connection.peer_address_type
    ra = state.bd_address.binary()
    rat = 0

    response = c1(pairing.k, pairing.r, pairing.preq, pairing.pres, iat, rat, ia, ra)
    {:reply, <<0x03>> <> reverse(response), %{state | pairing: pairing}}
  end

  def handle_call({:handle, <<0x04, random::binary>>}, _from, state) do
    # Handle Pairing Random

    pairing = %{state.pairing | ir: reverse(random)}
    ia = BlueHeron.Address.parse(state.connection.peer_address).binary()
    iat = state.connection.peer_address_type
    ra = state.bd_address.binary()
    rat = 0

    # Use c1() with peer random
    response = c1(pairing.k, pairing.ir, pairing.preq, pairing.pres, iat, rat, ia, ra)

    # Is confirmed?
    if pairing.confirm == response do
      # Inform callback that pairing completed
      state.io_handler.status_update(:success)
      {:reply, <<0x04>> <> reverse(pairing.r), %{state | pairing: pairing}}
    else
      Logger.warning("passkey missmatch")
      # Inform callback that pairing failed
      state.io_handler.status_update(:passkey_mismatch)

      {:reply, <<0x05, 0x04>>, %{state | pairing: nil}}
    end
  end

  def handle_call({:handle, <<0x05, reason>>}, _from, state) do
    Logger.warn("Pairing failed: #{reason}")
    # Inform callback that pairing failed
    state.io_handler.status_update(:fail)
    {:reply, nil, state}
  end

  def handle_call({:handle, <<0x06, _ltk::binary>>}, _from, state) do
    # Got LTK from central. We will not use it, it will connect to us in the future.
    {:reply, nil, state}
  end

  def handle_call(
        {:handle, <<0x07, _ediv::little-16, _rand::little-64>>},
        _from,
        state
      ) do
    # Got EDIV and Rand from central. We will not use it, it will connect to us in the future.
    {:reply, nil, state}
  end

  def handle_call({:handle, <<0x0A, _csrk::binary>>}, _from, state) do
    # Got CSRK from central. We will not use it, it will connect to us in the future.
    {:reply, nil, state}
  end

  def handle_call({:handle, msg}, _from, state) do
    Logger.warning("Unknown SMP request: #{inspect(msg)}")
    {:reply, nil, state}
  end

  def handle_call({:long_term_key_request, %{encrypted_diversifier: 0} = request}, _from, state) do
    # EDIV is 0 we use STK as a encryption key

    stk = s1(state.pairing.k, state.pairing.r, state.pairing.ir)

    command =
      LongTermKeyRequestReply.new(
        connection_handle: request.connection_handle,
        ltk: reverse(stk)
      )

    {:reply, command, %{state | stk_used: true}}
  end

  def handle_call({:long_term_key_request, request}, _from, state) do
    # TODO: Handle unknown EDIV
    {ediv, keys} = KeyManager.get(state.key_manager, request.encrypted_diversifier)

    command = reply_for_ltk_request(request, ediv, keys)
    {:reply, command, %{state | stk_used: false}}
  end

  def handle_call({:encryption_change, event}, _from, %{stk_used: true} = state) do
    # We got an encrypted channel, but we only used the short term key lets exchange keys

    # We are using the DATABASE LOOKUP described in the Bluetooth pecification
    # Version 5.3 | Vol 3, Part H Appendix B1
    {ediv,
     <<
       rand::bytes-size(8),
       ltk::bytes-size(16),
       csrk::bytes-size(16),
       irk::bytes-size(16)
     >>} = KeyManager.new(state.key_manager)

    # generate and send LTK using "Encryption Information" ACL message
    frame = acl(event.connection_handle, <<0x06>> <> reverse(ltk))
    BlueHeron.acl(state.ctx, frame)

    # generate and send EDIV and RAND using "Central Identification" ACL message
    frame = acl(event.connection_handle, <<0x07, ediv::little-16>> <> reverse(rand))
    BlueHeron.acl(state.ctx, frame)

    # generate and send IRK using "Identity Information" ACL message
    frame = acl(event.connection_handle, <<0x08>> <> reverse(irk))
    BlueHeron.acl(state.ctx, frame)

    # generate and send BD_ADDRESS using "Identity Address Information" ACL message
    frame = acl(event.connection_handle, <<0x09, 0>> <> reverse(state.bd_address.binary()))
    BlueHeron.acl(state.ctx, frame)

    # generate and send CSRK using "Signing Information" ACL message
    frame = acl(event.connection_handle, <<0x0A>> <> reverse(csrk))
    BlueHeron.acl(state.ctx, frame)

    {:reply, nil, %{state | authenticated: true}}
  end

  def handle_call({:encryption_change, _event}, _from, state) do
    # Authenticated using exchanged long term key
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
    <<_::binary-size(8), r1::binary-size(8)>> = r1
    <<_::binary-size(8), r2::binary-size(8)>> = r2
    r = r1 <> r2
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

  defp reply_for_ltk_request(request, _ediv, nil) do
    # EDIV does not exist, keys are "nil"
    Logger.warn("Authentication: 'EDIV' unknown for #{request.connection_handle}")
    LongTermKeyRequestNegativeReply.new(connection_handle: request.connection_handle)
  end

  defp reply_for_ltk_request(request, _ediv, keys) do
    # EDIV exists, we have keys
    <<rand::unsigned-64, ltk::bytes-size(16), _csrk::bytes-size(16), _irk::bytes-size(16)>> = keys

    if rand == request.random_number do
      LongTermKeyRequestReply.new(
        connection_handle: request.connection_handle,
        ltk: reverse(ltk)
      )
    else
      Logger.warn("Authentication: 'Rand' missmatch on handle #{request.connection_handle}")
      LongTermKeyRequestNegativeReply.new(connection_handle: request.connection_handle)
    end
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
