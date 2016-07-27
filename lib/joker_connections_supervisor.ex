defmodule  Joker.ConnectionsSupervisor do
  defstruct [
              parent_pid: nil,
              ref: nil,
              connection_type: nil,
              shutdown: nil,
              transport: nil,
              protocol: nil,
              protocol_options: nil,
              ack_timeout: nil,
              max_connections: nil
            ]

  def start_link(ref, connection_type, shutdown, transport, ack_timeout, protocol) do
    :proc_lib.start_link(__MODULE__, :init, [self, ref, connection_type, shutdown, transport, ack_timeout, protocol])
  end

  def start_protocol(connection_socket, connection_supervisor) do
    send(connection_supervisor, {__MODULE__, :start_protocol, self, connection_socket})
    receive do
      ^connection_supervisor -> :ok
    end
  end

  def init(parent_pid, ref, connection_type, shutdown, transport, ack_timeout, protocol) do
    Process.flag(:trap_exit, true)
    JokerServer.set_connection_supervisor(ref, self)
    max_connections = JokerServer.get_max_connections(ref)
    protocol_options = JokerServer.get_protocol_options(ref)
    :ok = :proc_lib.init_ack(parent_pid, {:ok, self})
    loop(%__MODULE__{parent_pid: parent_pid, ref: ref, connection_type: connection_type,
                     shutdown: shutdown, transport: transport, ack_timeout: ack_timeout,
                     protocol: protocol, protocol_options: protocol_options, max_connections: max_connections}, 0, 0, [])
  end

  def loop(state = %__MODULE__{parent_pid: parent_pid, ref: ref, connection_type: connection_type,
                               transport: transport, protocol: protocol, protocol_options: protocol_options,
                               max_connections: max_connections}, current_connections, children, sleepers) do
    receive do
      {__MODULE__, :start_protocol, acceptor_pid, connection_socket} ->
        case protocol.start_link(ref, connection_socket, transport, protocol_options) do
          {:ok, protocol_pid} ->
            shoot(state, current_connections, children, sleepers, acceptor_pid, connection_socket, protocol_pid, protocol_pid)
          {:ok, protocol_pid, protocol_supervisor_pid} when connection_type == :supervisor->
            shoot(state, current_connections, children, sleepers, acceptor_pid, connection_socket, protocol_supervisor_pid, protocol_pid)
          ret ->
            :io.format("Joker listener ~p connection process start failure; ~p:start_link/4 returned: ~p", [ref, protocol, ret])
            send(acceptor_pid, self)
            loop(state, current_connections, children, sleepers)
        end
      {__MODULE__, :active_connections, request_pid, tag} ->
        send(request_pid, {tag, current_connections})
        loop(state, current_connections, children, sleepers)
      {:remove_connections, ^ref} ->
        loop(state, current_connections - 1, children, sleepers)
      {:set_max_connections, new_max_connections} when new_max_connections > max_connections ->
        for asleep_acceptor_pid <- sleepers do
           send(asleep_acceptor_pid, self)
        end
        loop(%{state | max_connections: new_max_connections}, current_connections, children, [])
      {:set_max_connections, new_max_connections} ->
        loop(%{state | max_connections: new_max_connections}, current_connections, children, sleepers)
      {:set_protocol_options, protocol_options} ->
        loop(%{state | protocol_options: protocol_options}, current_connections, children, sleepers)
      {:EXIT, ^parent_pid, reason} ->
        terminate(state, reason, children)
      {:EXIT, protocol_pid, _reason} when sleepers == [] ->
        Process.delete(protocol_pid)
        loop(state, current_connections - 1, children - 1, sleepers)
      {:EXIT, protocol_pid, _reason} ->
        Process.delete(protocol_pid)
        [acceptor_pid | remained_sleepers] = sleepers
        send(acceptor_pid, self)
        loop(state, current_connections - 1, children - 1, remained_sleepers)
      message ->
        IO.puts "something wrong when starting protocol process"
        IO.inspect [ref, message]
    end
  end

  def shoot(state = %__MODULE__{ref: ref, transport: transport, ack_timeout: ack_timeout, max_connections: max_connections}, current_connections, children, sleepers, acceptor_pid, connection_socket, protocol_supervisor_pid, protocol_pid) do
    case transport.controlling_process(protocol_pid, connection_socket) do
      :ok ->
        send(protocol_pid, {:shoot, ref, transport, connection_socket, ack_timeout})
        Process.put(protocol_supervisor_pid, true)
        current_connections = current_connections + 1
        cond do
          current_connections < max_connections ->
            send(acceptor_pid, self)
            loop(state, current_connections, children + 1, sleepers)
          true ->
            loop(state, current_connections, children + 1, [acceptor_pid | sleepers])
        end
      {:error, _} ->
        transport.close(connection_socket)
        Process.exit(protocol_supervisor_pid, :kill)
        loop(state, current_connections, children, sleepers)
    end
  end

  def terminate(%__MODULE__{shutdown: :brutal_kill}, reason, _) do
    protocol_pids = Process.get_keys(true)
    for protocol_pid <- protocol_pids do
      Process.unlink(protocol_pid)
      Process.exit(protocol_pid, :kill)
    end
    exit(reason)
  end

  def terminate(%__MODULE__{shutdown: shutdown}, reason, children) do
    shutdown_children()
    if shutdown == :infinity do
      :ok
    else
      Process.send_after(self, :kill, shutdown)
    end
    wait_children(children)
    exit(reason)
  end

  defp shutdown_children do
    protocol_pids = Process.get_keys(true)
    for protocol_pid <- protocol_pids do
      Process.monitor(protocol_pid)
      Process.unlink(protocol_pid)
      Process.exit(protocol_pid, :shutdown)
    end
    :ok
  end

  defp wait_children(0) do
    :ok
  end

  defp wait_children(children) do
    receive do
      {:DOWN, _, :process, protocol_pid, _} ->
        Process.delete(protocol_pid)
        wait_children(children - 1)
      :kill ->
        protocol_pids = Process.get_keys(true)
        for protocol_pid <- protocol_pids do
          Process.exit(protocol_pid, :kill)
        end
        :ok
    end
  end
end
