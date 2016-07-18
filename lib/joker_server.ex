defmodule JokerServer do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  def set_new_listener_options(ref, max_connections, protocol_options) do
    GenServer.call(__MODULE__, {:set_new_listener_options, ref, max_connections, protocol_options})
  end

  def init(:ok) do
    {:ok, %{}}
  end

  def handle_call({:set_new_listener_options, ref, max_connections, protocol_options}, _from, state) do
    :ets.insert(:joker_server, {{:max_connections, ref}, max_connections})
    :ets.insert(:joker_server, {{:protocol_options, ref}, protocol_options})
    {:reply, :ok, state}
  end
end
