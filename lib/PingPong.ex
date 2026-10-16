defmodule PingPong do
  use GenServer

  #---------------- Servidor ------------------#

  def start_link(state)do
    GenServer.start_link(__MODULE__, state, name: __MODULE__)
  end

  def init(state) do
      {:ok, state}
  end

  def handle_call(:ping, _from, state) do
    {:reply, :pong, state}
  end

  #---------------- Cliente ------------------#

  def ping() do
    GenServer.call(PingPong, :ping)
  end

  def ping_pid(pid) do
    GenServer.call(pid, :ping)
  end

  def ping_remote(node) do
    GenServer.call({PingPong, node}, :ping)
  end
end

#GenServer.call({PingPong, :a@127.0.0.1}, :ping)
