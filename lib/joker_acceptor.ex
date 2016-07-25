defmodule Joker.Acceptor do
  def start_link(listen_socket, transport, connection_supervisor) do
    pid = spawn_link(__MODULE__, :loop, [listen_socket, transport, connection_supervisor])
    {:ok, pid}
  end

  def loop(listen_socket, transport, connection_supervisor) do
    case transport.accept(listen_socket) do
      {:ok, connection_socket} ->
        case transport.controlling_process(connection_supervisor, connection_socket) do
          :ok ->
            Joker.ConnectionsSupervisor.start_protocol(connection_socket, connection_supervisor)
          {:error, _} ->
            transport.close(connection_socket)
        end

      _ -> IO.puts("socket error")
    end
    loop(listen_socket, transport, connection_supervisor)
  end
end
