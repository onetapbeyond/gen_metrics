defmodule GenMetrics.GenStage.Manager do
  alias GenMetrics.GenStage.Manager
  alias GenMetrics.GenStage.Stage
  alias GenMetrics.GenStage.Summary
  alias GenMetrics.GenStage.Stats
  alias GenMetrics.GenStage.Window
  alias GenMetrics.GenStage.Metric
  alias GenMetrics.Utils.Math
  alias GenMetrics.Utils.Runtime
  alias GenMetrics.Utils.StatsPush

  @moduledoc false

  defstruct stages: %{}, summary_partials: %{}, summary_paired: %{},
    stats_partials: %{}, stats_paired: %{}

  def initialize do
    %Manager{}
  end

  def reinitialize(metrics) do
    %Manager{stages: metrics.stages,
             summary_partials: metrics.summary_partials,
             stats_partials: metrics.stats_partials}
  end

  def open_summary_metric(metrics, mod, pid, demand, ts) do
    metrics = register_pid_on_stage(metrics, mod, pid)
    do_open_summary_metric(metrics, mod, pid, demand, ts)
  end

  def close_summary_metric(metrics, mod, pid, events, ts) do
    do_close_summary_metric(metrics, mod, pid, events, ts)
  end

  def open_stats_metric(metrics, {mod, pid, demand, ts}) do
    metrics = register_pid_on_stage(metrics, mod, pid)
    do_open_stats_metric(metrics, {mod, pid, demand, ts})
  end

  def close_stats_metric(pipeline, metrics, {mod, pid, events, ts}) do
    do_close_stats_metric(pipeline, metrics, {mod, pid, events, ts})
  end

  def as_window(metrics, gen_stats, sample_rate) do
    window = %Window{summary: build_stage_summary(metrics, sample_rate)}
    if gen_stats do
      with stage_metrics <- build_stage_metrics(metrics),
           stage_stats <- build_stage_stats(stage_metrics, sample_rate),
      do: %Window{window | stats: stage_stats}
    else
      window
    end
  end

  #
  # Metrics manager private utility functions follow.
  #

  defp register_pid_on_stage(metrics, stage, pid) do
    stages = Map.update(metrics.stages, stage,
      MapSet.new |> MapSet.put(pid), & MapSet.put(&1, pid))
    %Manager{metrics | stages: stages}
  end

  defp do_open_summary_metric(metrics, _mod, pid, demand, ts) do
    mdemand = Metric.demand(demand, ts)
    summary_partials = Map.put(metrics.summary_partials, pid, mdemand)
    %Manager{metrics | summary_partials: summary_partials}
  end

  defp do_close_summary_metric(metrics, _mod, pid, events, ts) do
    if Map.has_key?(metrics.summary_partials, pid) do
      {partial, summary_partials} = Map.pop(metrics.summary_partials, pid)
      summary_paired =
        Metric.pair(metrics.summary_paired, pid, events, ts, partial)
      %Manager{metrics | summary_partials: summary_partials,
               summary_paired: summary_paired}
    else
      metrics
    end
  end

  defp do_open_stats_metric(metrics, {_mod, pid, demand, ts}) do
    mdemand = Metric.demand(demand, ts)
    stats_partials = Map.put(metrics.stats_partials, pid, mdemand)
    %Manager{metrics | stats_partials: stats_partials}
  end

  defp do_close_stats_metric(pipeline, metrics, {mod, pid, events, ts}) do
    if Map.has_key?(metrics.stats_partials, pid) do
      {partial, partials} = Map.pop(metrics.stats_partials, pid)
      mevent = Metric.event(partial, events, ts)
      statsd_args = {mod, pid, mevent, partials}
      case pipeline.opts[:statistics] do
        :statsd  ->
          push_metric_to_statsd(pipeline, metrics, statsd_args)
        :datadog ->
          push_metric_to_datadog(pipeline, metrics, statsd_args)
        _        ->
          push_metric_in_memory(pipeline, metrics, pid, mevent, partials)
      end
    else
      metrics
    end
  end

  defp build_stage_summary(metrics, sample_rate) do
    for {stage, pids} <- metrics.stages, pid <- pids, into: [] do
      summary = generate_stage_summary(Map.get(metrics.summary_paired,
            pid, Metric.no_pair), sample_rate)
      %Summary{summary | name: stage, pid: pid}
    end
  end

  defp build_stage_metrics(metrics) do
    for {stage, pids} <- metrics.stages, pid <- pids, into: [] do
      {stage, pid, Map.get(metrics.stats_paired, pid, [])}
    end
  end

  defp build_stage_stats([], _), do: []
  defp build_stage_stats(stage_metrics, sample_rate) do
    for {module, pid, metrics} <- stage_metrics do
      len = length(metrics)
      %Stage{name: module, pid: pid,
             demand: generate_demand_stats(metrics, len, sample_rate),
             events: generate_events_stats(metrics, len, sample_rate),
             timings: generate_timings_stats(metrics, len, sample_rate)}
    end
  end

  defp generate_stage_summary({calls, demand, events, time_on_callbacks},
    sample_rate) do
    do_generate_stage_summary(calls, demand, events,
      Runtime.nano_to_milli(time_on_callbacks), sample_rate)
  end

  defp generate_stage_summary(stage = %Stage{}, sample_rate) do
    do_generate_stage_summary(stage.demand.calls,
      stage.demand.total, stage.events.total,
      Runtime.micro_to_milli(stage.timings.total), sample_rate)
  end

  defp do_generate_stage_summary(calls, demand, events,
    time_on_callbacks, sample_rate) do
    srate_multiplier = 1 / sample_rate
    %Summary{callbacks: round(calls * srate_multiplier),
             demand: round(demand * srate_multiplier),
             events: round(events * srate_multiplier),
             time_on_callbacks: round(time_on_callbacks * srate_multiplier)}
  end

  defp generate_demand_stats(metrics, len, sample_rate) do
    demand = metrics |> Enum.map(& &1.demand) |> Enum.sort
    generate_stats(demand, len, sample_rate)
  end

  defp generate_events_stats(metrics, len, sample_rate) do
    events = metrics |> Enum.map(& &1.events) |> Enum.sort
    generate_stats(events, len, sample_rate)
  end

  defp generate_timings_stats(metrics, len, sample_rate) do
    durations = metrics |> Enum.map(& &1.duration) |> Enum.sort
    generate_stats(durations, len, sample_rate)
  end

  defp generate_stats(data, len, sample_rate) do
    srate_multiplier = 1 / sample_rate
    %Stats{callbacks: round(len * srate_multiplier),
           min: Math.min(data), max: Math.max(data),
           total: round(Math.sum(data) * srate_multiplier),
           mean: Math.mean(data, len),
           stdev: Math.stdev(data, len), range: Math.range(data)}
  end

  defp push_metric_in_memory(_cluster, metrics, pid, mevent, stats_partials) do
    stats_paired =
      Map.update(metrics.stats_paired, pid, [mevent], & [mevent | &1])
    %Manager{metrics | stats_partials: stats_partials,
             stats_paired: stats_paired}
  end

  defp push_metric_to_statsd(pipeline, metrics, {mod, pid, mevent, partials}) do
    StatsPush.statsd(pipeline.name, mod, pid, nil, mevent)
    %Manager{metrics | stats_partials: partials}
  end

  defp push_metric_to_datadog(pipeline, metrics, {mod, pid, mevent, partials}) do
    StatsPush.datadog(pipeline.name, mod, pid, nil, mevent)
    %Manager{metrics | stats_partials: partials}
  end

end
