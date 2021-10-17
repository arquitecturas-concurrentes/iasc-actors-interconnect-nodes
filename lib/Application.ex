
defmodule InterconnectNodesApplication do
  use Application

  def start(_type, _args) do
    children = [
      PingPongSupervisor,
      Cluster.Observer.Supervisor
    ]

    opts = [strategy: :one_for_one, name: SupervisorDeSupervisores]
    Supervisor.start_link(children, opts)
  end
end
