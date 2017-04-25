defmodule GenMetrics.GenServer.Server do
  alias GenMetrics.GenServer.Stats

  @moduledoc """
  A struct used to aggregate statistical metrics data for a GenServer process.

  The fields are:
  * `name` - the module name for the GenServer process

  * `pid` - the `pid` for the GenServer process

  * `calls` - `GenMetrics.GenServer.Stats` for `GenServer.handle_call/3` callbacks

  * `casts` - `GenMetrics.GenServer.Stats` for `GenServer.handle_cast/2` callbacks

  * `infos` - `GenMetrics.GenServer.Stats` for `GenServer.handle_info/2` callbacks
  """

  defstruct name: nil, pid: nil,
    calls: %Stats{}, casts: %Stats{}, infos: %Stats{}

end
