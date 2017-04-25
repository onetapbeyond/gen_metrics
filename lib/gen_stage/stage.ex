defmodule GenMetrics.GenStage.Stage do
  alias GenMetrics.GenStage.Stats

  @moduledoc """
  A struct used to aggregate statistical metrics data for a GenStage process.

  The fields are:
  * `name` - the module name for the GenStage process

  * `pid` - the `pid` for the GenStage process

  * `demand` - `GenMetrics.GenStage.Stats` for upstream demand

  * `events` - `GenMetrics.GenStage.Stats` for emitted events

  * `timings` - `GenMetrics.GenStage.Stats` for time on GenStage callbacks
  """

  defstruct name: nil, pid: nil,
    demand: %Stats{}, events: %Stats{}, timings: %Stats{}

end
