defmodule GenMetrics.Utils.StatsPush do
  use Statix, runtime_config: true

  @moduledoc false

  alias GenMetrics.GenServer
  alias GenMetrics.GenStage
  alias GenMetrics.Utils.Runtime

  @genserver_prefix "GenMetrics.GenServer.Cluster"
  @genstage_prefix  "GenMetrics.GenStage.Pipeline"
  @genserver_dogtag "genserver"
  @genstage_dogtag  "genstage"
  @count  ".count"
  @demand ".demand"
  @events ".events"
  @stats  ".stats"
  @timing ".timing"
  @total  ".total"
  @sample_rate Application.get_env(:gen_metrics, :sample_rate, 1.0)

  def statsd(context, mod, pid, fun, %GenServer.Metric{} = metric) do
    base = as_label(@genserver_prefix, context, mod, pid, fun)
    __MODULE__.increment(base <> @count)
    __MODULE__.timing(base <> @stats, Runtime.nano_to_milli(metric.duration))
  end

  def statsd(context, mod, pid, _fun, %GenStage.Metric{} = metric) do
    base = as_label(@genstage_prefix, context, mod, pid)
    __MODULE__.increment(base <> @count)
    __MODULE__.increment(base <> @demand <> @total, metric.demand)
    __MODULE__.increment(base <> @events <> @total, metric.events)
    __MODULE__.timing(base <> @timing, Runtime.nano_to_milli(metric.duration))
  end

  def datadog(context, mod, pid, fun, %GenServer.Metric{} = metric) do
    base = as_label(@genserver_prefix, context, mod, pid, fun)
    dogtag = as_dogtag(@genserver_dogtag, context)
    __MODULE__.increment(base <> @count, 1,
      tags: [dogtag], sample_rate: @sample_rate)
    __MODULE__.histogram(base <> @stats,
      Runtime.nano_to_milli(metric.duration),
      tags: [dogtag], sample_rate: @sample_rate)
  end

  def datadog(context, mod, pid, _fun, %GenStage.Metric{} = metric) do
    base = as_label(@genstage_prefix, context, mod, pid)
    dogtag = as_dogtag(@genstage_dogtag, context)
    __MODULE__.increment(base <> @count, 1,
      tags: [dogtag], sample_rate: @sample_rate)
    __MODULE__.increment(base <> @demand <> @total, metric.demand,
      tags: [dogtag], sample_rate: @sample_rate)
    __MODULE__.increment(base <> @events <> @total, metric.events,
      tags: [dogtag], sample_rate: @sample_rate)
    __MODULE__.histogram(base <> @demand, metric.demand,
      tags: [dogtag], sample_rate: @sample_rate)
    __MODULE__.histogram(base <> @events, metric.events,
      tags: [dogtag], sample_rate: @sample_rate)
    __MODULE__.histogram(base <> @timing,
      Runtime.nano_to_milli(metric.duration),
      tags: [dogtag], sample_rate: @sample_rate)
  end

  defp as_label(prefix, cluster, mod, _pid, fun \\ nil) do
    if fun do
      [prefix, cluster, as_mod_label(mod), as_fun_label(fun)]
      |> build_label
    else
      [prefix, cluster, as_mod_label(mod)] |> build_label
    end
  end

  # defp as_pid_label(pid) when is_pid(pid) do
  #   Regex.replace(~r/\D/, "#{inspect pid}", "")
  # end

  defp as_mod_label(mod) when is_atom(mod) do
    "#{inspect mod}" |> String.split(".") |> Enum.reverse() |> Enum.fetch!(0)
  end

  defp as_fun_label(fun) when is_atom(fun) do
    Atom.to_string fun
  end
  defp as_fun_label(fun), do: fun

  defp build_label(fragments) do
    label = fragments |> Enum.join(".")
    Regex.replace(~r/\.\./, label, ".")
  end

  defp as_dogtag(prefix, context) do
    [prefix, context] |> build_label
  end

end
