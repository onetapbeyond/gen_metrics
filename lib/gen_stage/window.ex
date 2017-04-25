defmodule GenMetrics.GenStage.Window do

  @moduledoc """
  A struct used by the GenMetrics reporting process to periodically
  publish metrics data for a GenStage pipeline.

  The fields are:

  * `pipeline` - the associated `GenMetrics.GenStage.Pipeline`

  * `start` - the start time for the current metrics window interval

  * `duration` - the length (ms) of the current metrics window interval

  * `summary` - a list of `GenMetrics.GenStage.Summary`, item per process
  on the pipeline

  * `stats` - (optional) a list of `GenMetrics.GenStage.Stage`
  """

  defstruct pipeline: nil, start: 0, duration: 0, stats: [], summary: []

end
