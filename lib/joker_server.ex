defmodule JokerServer do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  def get_max_connections(ref) do
    :ets.lookup_element(:joker_server, {:max_connections, ref}, 2)
  end

  def get_protocol_options(ref) do
    :ets.lookup_element(:joker_server, {:protocol_options, ref}, 2)
  end

  def set_new_listener_options(ref, max_connections, protocol_options) do
    true = GenServer.call(__MODULE__, {:set_new_listener_options, ref, max_connections, protocol_options})
  end

  def get_connection_supervisor(ref) do
    :ets.lookup_element(:joker_server, {:connection_supervisor, ref}, 2)
  end

  def set_connection_supervisor(ref, connection_supervisor) do
    true = GenServer.call(__MODULE__, {:set_connection_supervisor, ref, connection_supervisor})
  end

  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call({:set_new_listener_options, ref, max_connections, protocol_options}, _from, state) do
    :ets.insert(:joker_server, {{:max_connections, ref}, max_connections})
    :ets.insert(:joker_server, {{:protocol_options, ref}, protocol_options})
    {:reply, true, state}
  end

  def handle_call({:set_connection_supervisor, ref, connection_supervisor}, _from, state) do
    true = :ets.insert(:joker_server, {{:connection_supervisor, ref}, connection_supervisor})
    {:reply, true, state}
  end
end
