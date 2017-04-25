defmodule GenMetrics.GenStage.Stage do
  alias GenMetrics.GenStage.Stats

  @moduledoc false

  defstruct name: nil, pid: nil,
    demand: %Stats{}, events: %Stats{}, timings: %Stats{}
end
