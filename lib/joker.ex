defmodule Joker do
  def start(_type, _args) do
    Joker.Supervisor.start_link
  end

  def start_listener(ref, acceptor_count, transport, transport_options, protocol, protocol_options) do
    Supervisor.start_child(Joker.Supervisor, child_spec(ref, acceptor_count, transport, transport_options, protocol, protocol_options))
  end

  defp child_spec(ref, acceptor_count, transport, transport_options, protocol, protocol_options) do
    import Supervisor.Spec
    supervisor(Joker.ListenerSupervisor, [ref, acceptor_count, transport, transport_options, protocol, protocol_options], [id: {Joker.ListenerSupervisor, ref}])
  end
end
