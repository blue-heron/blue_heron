defmodule BlueHeron.SMP.KeyManager do
  @moduledoc "Handles storage of keys for SMP"
  use GenServer

  def start_link(path) do
    GenServer.start_link(__MODULE__, path)
  end

  def init(path) do
    {:ok, %{key_file: path}}
  end

  def new(manager) do
    GenServer.call(manager, :new)
  end

  def get(manager, index) do
    GenServer.call(manager, {:get, index})
  end

  def handle_call(:new, _from, state) do
    data = read_or_create(state.key_file)
    {index, keys} = generate_keys(data)
    data = Map.put(data, index, keys)
    File.write!(state.key_file, :erlang.term_to_binary(data))
    {:reply, {index, keys}, state}
  end

  def handle_call({:get, index}, _from, state) do
    data = read_or_create(state.key_file)
    keys = get_keys(data, index)
    {:reply, {index, keys}, state}
  end

  defp generate_keys(data) do
    <<key::little-unsigned-16>> = :crypto.strong_rand_bytes(2)
    val = :crypto.strong_rand_bytes(56)

    # Make sure key (index) is unique
    if Map.has_key?(data, key) do
      generate_keys(data)
    else
      {key, val}
    end
  end

  defp get_keys(data, index) do
    case Map.fetch(data, index) do
      {:ok, keys} -> keys
      :error -> nil
    end
  end

  defp read_or_create(file) do
    case File.read(file) do
      {:ok, content} -> :erlang.binary_to_term(content)
      {:error, _reason} -> %{}
    end
  end
end
