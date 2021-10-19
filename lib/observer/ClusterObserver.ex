defmodule Cluster.Observer do
  use GenServer
  require Logger

  def start_link(_)do
    GenServer.start_link(__MODULE__, %{})
  end

  @impl GenServer
  def init(state) do
    # https://erlang.org/doc/man/net_kernel.html#monitor_nodes-1
    :net_kernel.monitor_nodes(true)

    {:ok, state}
  end

  @impl GenServer
  @doc """
  Handler that will be called when a node has left the cluster.
  """
  def handle_info({:nodedown, node}, state) do
    Logger.info("---- Node down: #{node} ----")

    {:noreply, state}
  end

  @impl GenServer
  @doc """
  Handler that will be called when a node has joined the cluster.
  """
  def handle_info({:nodeup, node}, state) do
    Logger.info("---- Node up: #{node} ----")

    {:noreply, state}
  end
end