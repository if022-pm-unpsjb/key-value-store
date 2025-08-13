defmodule KeyValueStoreDistributed do
  use GenServer

  ## Cliente API

  def start_link(name \\ :master, initial_state \\ %{}, opts \\ []) do
    GenServer.start_link(__MODULE__, {initial_state, opts}, name: {:global, name})
  end

  def put(key, value) do
    genserver_call({:put, key, value})
  end

  def get(key) do
    genserver_call({:get, key})
  end

  def delete(key) do
    genserver_call({:delete, key})
  end

  def add_slave(slave_pid) do
    genserver_call({:add_slave, {:global, slave_pid}})
  end

  defp genserver_call(params) do
    GenServer.call({:global, :master}, params)
  end

  ## Callbacks del servidor

  @impl true
  def init({initial_state, _opts}) do
    state = %{data: initial_state, slaves: []}
    {:ok, state}
  end

  @impl true
  def handle_call({:put, key, value}, _from, state) do
    new_state = Map.put(state.data, key, value)
    Enum.each(state.slaves, fn slave_pid ->
      GenServer.cast(slave_pid, {:replicate_put, key, value})
    end)
    {:reply, :ok, %{state | data: new_state}}
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    value = Map.get(state.data, key)
    {:reply, value, state}
  end

  @impl true
  def handle_call({:delete, key}, _from, state) do
    new_state = Map.delete(state.data, key)
    Enum.each(state.slaves, fn slave_pid ->
      GenServer.cast({slave_pid}, {:replicate_delete, key})
    end)
    {:reply, :ok, %{state | data: new_state}}
  end

  @impl true
  def handle_call({:add_slave, slave_pid}, _from, state) do
    new_state = %{state | slaves: [slave_pid | state.slaves]}
    {:reply, :ok, new_state}
  end

  # Manejamos los mensajes asíncronos
  @impl true
  def handle_cast({:replicate_put, key, value}, state) do
    new_state = Map.put(state.data, key, value)
    {:noreply, %{state | data: new_state}}
  end

  @impl true
  def handle_cast({:replicate_delete, key}, state) do
    new_state = Map.delete(state.data, key)
    {:noreply, %{state | data: new_state}}
  end
end
