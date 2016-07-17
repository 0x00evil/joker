defmodule Joker do
  def start(_type, _args) do
    Joker.Supervisor.start_link
  end
end
