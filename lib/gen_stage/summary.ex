defmodule GenMetrics.GenStage.Summary do

  @moduledoc """
  A struct used to report summary metrics data for a GenStage process.
  The numbers reported reflect totals during a given metrics collection
  window interval.

  The fields are:

  * `stage` - the module name for the GenStage process

  * `pid` - the `pid` for the GenStage process

  * `callbacks` - the number of callbacks on the GenStage process

  * `time_on_callbacks` - the number of milliseconds spent on callbacks

  * `demand` - the upstream demand on the GenStage process

  * `events` - the number of events emitted by the GenStage process
  """

  defstruct stage: nil, pid: nil,
    callbacks: 0, time_on_callbacks: 0, demand: 0, events: 0

end
