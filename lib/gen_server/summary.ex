defmodule GenMetrics.GenServer.Summary do

  @moduledoc """
  A struct used to report summary metrics data for a GenServer process.
  The numbers reported reflect totals during a given metrics collection
  window interval.

  The fields are:

  * `name` - the module name for the GenServer process

  * `pid` - the `pid` for the GenServer process

  * `calls` - the number of `GenServer.handle_call/3` calls

  * `casts` - the number of `GenServer.handle_cast/2` calls

  * `infos` - the number of `GenServer.handle_info/2` calls

  * `time_on_calls` - the number of milliseconds spent on calls

  * `time_on_casts` - the number of milliseconds spent on casts

  * `time_on_infos` - the number of milliseconds spent on infos
  """

  defstruct name: nil, pid: nil,
    calls: 0, casts: 0, infos: 0,
    time_on_calls: 0, time_on_casts: 0, time_on_infos: 0

end
