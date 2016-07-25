defmodule Joker.AcceptorsSupervisor do
  use Supervisor

  def start_link(ref, acceptors_count, transport, transport_options) do
    Supervisor.start_link(__MODULE__, [ref, acceptors_count, transport, transport_options], [name: __MODULE__])
  end

  def init([ref, acceptors_count, transport, transport_options]) do
    connection_supervisor = JokerServer.get_connection_supervisor(ref)
    listen_socket = transport.listen(transport_options)

    children = for n <- 1..acceptors_count do
       worker(Joker.Acceptor, [listen_socket, transport, connection_supervisor], [id: {:acceptor, self, n}])
    end

    strategy = [strategy: :one_for_one]
    supervise(children, strategy)
  end
end
