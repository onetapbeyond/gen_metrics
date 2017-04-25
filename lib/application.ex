defmodule GenMetrics.Application do
  @moduledoc false
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
        supervisor(GenMetrics.GenServer.Supervisor, []),
        supervisor(GenMetrics.GenStage.Supervisor, []),
        supervisor(GenMetrics.Reporter.Supervisor, [])
    ]

    opts = [strategy: :one_for_one, name: GenMetrics.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
