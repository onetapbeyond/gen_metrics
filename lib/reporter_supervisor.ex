defmodule GenMetrics.Reporter.Supervisor do
  use Supervisor

  @moduledoc false

  def start_link do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init(_) do

    children = [
      worker(GenMetrics.Reporter,
        [GenMetrics.GenServer.Reporter],
        [id: GenMetrics.GenServer.Reporter]),
      worker(GenMetrics.Reporter,
        [GenMetrics.GenStage.Reporter],
        [id: GenMetrics.GenStage.Reporter])
    ]

    supervise(children, strategy: :one_for_one)
  end

end
