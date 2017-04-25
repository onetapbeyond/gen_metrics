defmodule GenMetrics.GenStage.Metric do
  @moduledoc false
  alias GenMetrics.GenStage.Metric
  alias GenMetrics.Utils.Runtime

  @nano_to_micro 1000

  defstruct demand: 0, events: 0, duration: 0

  def demand(demand, start) do
    %Metric{demand: demand, duration: start}
  end

  def event(partial, events, ts) do
    %Metric{partial | events: events,
            duration: Runtime.safe_div(ts - partial.duration, @nano_to_micro)}
  end

  def pair(summary_paired, pid, events, ts, partial) do
    start_pid = {1, partial.demand, events, ts - partial.duration}
    Map.update(summary_paired, pid, start_pid,
      fn {calls, dmd, evts, toc} ->
        {calls + 1, dmd + partial.demand, evts + events,
         toc + (ts - partial.duration)}
      end)
  end

  def no_pair do
    {0, 0, 0, 0}
  end

end
