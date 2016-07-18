defmodule Joker.Acceptor do
  def start_link(ref, transport, transport_options) do
    pid = spawn_link(__MODULE__, :loop, [ref, transport, transport_options])
    {:ok, pid}
  end

  def loop(ref, transport, transport_options) do
    receive do
      :stop -> :ok
    end
  end
end
