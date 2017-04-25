defmodule GenMetrics.GenServer.Window do

  @moduledoc """
  A struct used by the GenMetrics reporting process to periodically
  publish metrics data for a GenServer cluster.

  The fields are:

  * `cluster` - the associated `GenMetrics.GenServer.Cluster`

  * `start` - the start time for the current metrics window interval

  * `duration` - the length (ms) of the current metrics window interval

  * `summary` - a list of `GenMetrics.GenServer.Summary`, item per process
  on the pipeline

  * `stats` - (optional) a list of `GenMetrics.GenServer.Stats`, item per
  process on the pipeline
  """

  defstruct cluster: nil, start: 0, duration: 0, stats: [], summary: []
end
