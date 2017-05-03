defmodule GenMetrics.Application do
  @moduledoc false
  use Application

  alias GenMetrics.GenServer
  alias GenMetrics.GenStage
  alias GenMetrics.Reporter
  alias GenMetrics.Utils.StatsPush

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Activate Statix (statsd) connection on startup.
    :ok = StatsPush.connect

    children = [
        supervisor(GenServer.Supervisor, []),
        supervisor(GenStage.Supervisor, []),
        supervisor(Reporter.Supervisor, [])
    ]

    opts = [strategy: :one_for_one, name: GenMetrics.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
