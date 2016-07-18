defmodule  Joker.ConnectionsSupervisor do
  def start_link(ref, connection_type, shutdown, transport, ack_timeout, protocol) do
    :proc_lib.start_link(__MODULE__, :init, [self, ref, connection_type, shutdown, transport, ack_timeout, protocol])
  end

  def init(parent_pid, _ref, _connection_type, _shutdown, _transport, _ack_timeout, _protocol) do
    Process.flag(:trap_exit, true)
    :ok = :proc_lib.init_ack(parent_pid, {:ok, self})
    receive do
      :stop -> :ok
    end
  end
end
