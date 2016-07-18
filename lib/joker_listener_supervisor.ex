defmodule Joker.ListenerSupervisor do
  use Supervisor

  def start_link(ref, acceptors_count, transport, transport_options, protocol, protocol_options) do
    max_connections = Keyword.get(transport_options, :max_connections, 1024)
    JokerServer.set_new_listener_options(ref, max_connections, protocol_options)
    Supervisor.start_link(__MODULE__, [ref, acceptors_count, transport, transport_options, protocol])
  end

  def init([ref, acceptors_count, transport, transport_options, protocol]) do
    ack_timeout = Keyword.get(transport_options, :ack_timeout, 5000)
    connection_type = Keyword.get(transport_options, :connection_type, :worker)
    shutdown = Keyword.get(transport_options, :shutdown, 5000)
    children = [
      supervisor(Joker.ConnectionsSupervisor, [ref, connection_type, shutdown, transport, ack_timeout, protocol]),
      supervisor(Joker.AcceptorsSupervisor, [ref, acceptors_count, transport, transport_options])
    ]
    strategy = [strategy: :rest_for_one]
    supervise(children, strategy)
  end
end
