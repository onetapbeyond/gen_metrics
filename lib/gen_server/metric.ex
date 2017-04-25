defmodule GenMetrics.GenServer.Metric do
  @moduledoc false
  alias GenMetrics.GenServer.Metric
  alias GenMetrics.Utils.Runtime

  @nano_to_micro 1000

  defstruct start: 0, duration: 0

  def partial(ts) do
    ts
  end

  def pair(summary_paired, mkey, ts, partial) do
    start_mkey = {1, ts - partial}
    Map.update(summary_paired, mkey, start_mkey,
      fn {calls, toc} -> {calls + 1, toc + (ts - partial)} end)
  end

  def no_pair do
    {0, 0}
  end

  def start(ts) do
    %Metric{start: ts}
  end

  def stop(partial, ts) do
    %Metric{partial |
            duration: Runtime.safe_div(ts - partial.start, @nano_to_micro)}
  end

end
