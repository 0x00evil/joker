defmodule Joker.AcceptorsSupervisor do
  use Supervisor

  def start_link(ref, acceptors_count, transport, transport_options) do
    Supervisor.start_link(__MODULE__, [ref, acceptors_count, transport, transport_options])
  end

  def init([ref, acceptors_count, transport, transport_options]) do
    children = for n <- 1..acceptors_count do
       worker(Joker.Acceptor, [ref, transport, transport_options], [id: {:acceptor, self, n}])
    end

    strategy = [strategy: :one_for_one]
    supervise(children, strategy)
  end
end
