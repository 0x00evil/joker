defmodule Joker.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, [name: __MODULE__])
  end

  def init(:ok) do
    :joker_server = :ets.new(:joker_server, [:named_table, :public, :ordered_set])

    child = [worker(JokerServer, [])]
    opts = [strategy: :one_for_one]
    supervise(child, opts)
  end
end
