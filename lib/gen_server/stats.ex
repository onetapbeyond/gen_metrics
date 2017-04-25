defmodule GenMetrics.GenServer.Stats do

  @moduledoc """
  A struct used to report statistical metrics data for a GenServer process.

  The fields are:

  * `callbacks` - the total number of callbacks handled by the process

  * `total` - the total time spent (µs) on all callbacks

  * `max` - the maximum time spent (µs) on any callback

  * `min` - the minimum time spent (µs) on any callback

  * `mean` - the mean time spent (µs) on any callback

  * `stdev` - the standard deviation around the mean time spent (µs) on
  any callback

  * `range` - the difference between max and min time spent (µs) on all callbacks
  """

  defstruct callbacks: 0, min: 0, max: 0, total: 0,
    mean: 0, stdev: 0, range: 0

end
