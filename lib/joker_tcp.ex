defmodule Joker.TCP do
  def listen(transport_options) do
    {:ok, listen_socket} = :gen_tcp.listen(0, transport_options)
    listen_socket
  end

  def accept(listen_socket) do
    :gen_tcp.accept(listen_socket, :infinity)
  end

  def accept(listen_socket, timeout) do
    :gen_tcp.accept(listen_socket, timeout)
  end

  def controlling_process(pid, socket) do
    :gen_tcp.controlling_process(socket, pid)
  end

  def close(socket) do
    :gen_tcp.close(socket)
  end
end
