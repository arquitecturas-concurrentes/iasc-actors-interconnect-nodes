defmodule Cluster.Observer do
  use GenServer
  require Logger

  def start_link(_)do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl GenServer
  def init(state) do
    :net_kernel.monitor_nodes(true)

    {:ok, state}
  end

  @impl GenServer
  def handle_info({:nodedown, node}, state) do
    # A node left the cluster
    Logger.info("--- Node down: #{node}")

    {:noreply, state}
  end

  def handle_info({:nodeup, node}, state) do
    # A new node joined the cluster
    Logger.info("--- Node up: #{node}")

    {:noreply, state}
  end
end