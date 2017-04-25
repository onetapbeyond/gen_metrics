defmodule GenMetrics.GenServer.Server do
  alias GenMetrics.GenServer.Stats

  @moduledoc false

  defstruct name: nil, pid: nil,
    calls: %Stats{}, casts: %Stats{}, infos: %Stats{}
end
