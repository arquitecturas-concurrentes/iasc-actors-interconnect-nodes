defmodule PingPong do
  use GenServer

  #---------------- Servidor ------------------#

  def start_link(state)do
    GenServer.start_link(__MODULE__, state, name: PingPong)
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

end

#GenServer.call({PingPong, :a@altair}, :ping)