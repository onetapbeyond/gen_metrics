defmodule GenMetrics.GenServer.Monitor do
  use GenServer
  alias GenMetrics.GenServer.Manager
  alias GenMetrics.GenServer.Monitor
  alias GenMetrics.GenServer.Cluster
  alias GenMetrics.GenServer.Window
  alias GenMetrics.Reporter
  alias GenMetrics.Utils.Runtime

  @moduledoc false
  @call_cast_info [:handle_call, :handle_cast, :handle_info]
  @window_interval_default 1000

  defstruct cluster: %Cluster{}, metrics: nil, start: 0, duration: 0

  def start_link(cluster) do
    GenServer.start_link(__MODULE__, cluster)
  end

  def init(cluster) do
    with {:ok, _}     <- validate_modules(cluster),
         {:ok, _}     <- validate_behaviours(cluster),
         {:ok, _}     <- activate_tracing(cluster),
         state        <- initialize_monitor(cluster),
      do: start_monitor(state)
  end

  #
  # Handlers for intercepting :erlang.trace/3 and :erlang.trace_pattern/2
  # callbacks for modules registered on the cluster.
  #

  def handle_info({:trace_ts, pid, :call, {mod, fun, _args}, ts}, state) do
    {:noreply,
     do_intercept_call_request(state, mod, pid, fun, ts)}
  end

  # Intercept {:reply, reply, new_state}
  def handle_info({:trace_ts, pid, :return_from, {mod, fun, _arity},
                   {:reply, _, _}, ts}, state) do
    {:noreply,
     do_intercept_call_response(state, mod, pid, fun, ts)}
  end

  # Intercept {:reply, reply, new_state, timeout | :hibernate}
  def handle_info({:trace_ts, pid, :return_from, {mod, fun, _arity},
                   {:reply, _, _, _}, ts}, state) do
    {:noreply,
     do_intercept_call_response(state, mod, pid, fun, ts)}
  end

  # Intercept {:noreply, new_state}
  def handle_info({:trace_ts, pid, :return_from, {mod, fun, _arity},
                   {:noreply, _}, ts}, state) do
    {:noreply,
     do_intercept_call_response(state, mod, pid, fun, ts)}
  end

  # Intercept {:noreply, new_state, timeout | :hibernate}
  def handle_info({:trace_ts, pid, :return_from, {mod, fun, _arity},
                   {:noreply, _, _}, ts}, state) do
    {:noreply,
     do_intercept_call_response(state, mod, pid, fun, ts)}
  end

  # Intercept {:stop, reason, reply, new_state}
  def handle_info({:trace_ts, pid, :return_from, {mod, fun, _arity},
                   {:stop, _, _, _}, ts}, state) do
    {:noreply,
     do_intercept_call_response(state, mod, pid, fun, ts)}
  end

  # Intercept {:stop, reason, new_state}
  def handle_info({:trace_ts, pid, :return_from, {mod, fun, _arity},
                   {:stop, _, _}, ts}, state) do
    {:noreply,
     do_intercept_call_response(state, mod, pid, fun, ts)}
  end

  # Report and rollover metrics window.
  def handle_info(:rollover_metrics_window, state) do
    now = :erlang.system_time
    state = %Monitor{state | duration: Runtime.nano_to_milli(now - state.start)}
    window = Manager.as_window(state.metrics, statistics?(state.cluster))
    window = %Window{window | cluster: state.cluster,
                     start: state.start, duration: state.duration}
    Reporter.push(GenMetrics.GenServer.Reporter, window)
    Process.send_after(self(), :rollover_metrics_window, window_interval(state))
    {:noreply, initialize_monitor(state.cluster, state.metrics)}
  end

  # Catch-all for calls not intercepted by monitor.
  def handle_info(_msg, state), do: {:noreply, state}

  #
  # Private utility functions follow.
  #

  # Initialize GenServer state for monitor.
  defp initialize_monitor(cluster, metrics \\ nil)  do
    if metrics do
      %Monitor{cluster: cluster,
               metrics: Manager.reinitialize(metrics),
               start: :erlang.system_time}
    else
        %Monitor{cluster: cluster,
                 metrics: Manager.initialize(),
                 start: :erlang.system_time}
    end
  end

  # Initialize periodic callback for metrics reporting and window rollover.
  defp start_monitor(state) do
    Process.send_after(self(), :rollover_metrics_window, window_interval(state))
    {:ok, state}
  end

  # Activate tracing for servers within cluster.
  defp activate_tracing(cluster) do
    :erlang.trace(:all, true, [:call, :monotonic_timestamp])

    for server <- cluster.servers do

      if synchronous?(cluster) do
        :erlang.trace_pattern({server, :handle_call, 3},
          [{:_, [], [{:return_trace}]}])
      end
      :erlang.trace_pattern({server, :handle_cast, 2},
        [{:_, [], [{:return_trace}]}])
      :erlang.trace_pattern({server, :handle_info, 2},
        [{:_, [], [{:return_trace}]}])
    end

    {:ok, cluster}
  end

  # Validate cluster modules can be loaded or report failures.
  defp validate_modules(cluster) do
    case require_modules(cluster) do
      []   -> {:ok, cluster}
      errs -> {:stop, {:bad_cluster, errs}}
    end
  end

  # Ensure cluster modules are available and can be loaded.
  defp require_modules(cluster) do
    cluster.servers
    |> Enum.uniq
    |> Runtime.require_modules
  end

  # Validate cluster modules implement GenServer or report failures.
  defp validate_behaviours(cluster) do
    case require_behaviour(cluster, GenServer) do
      []   -> {:ok, cluster}
      errs -> {:stop, {:bad_cluster, errs}}
    end
  end

  # Ensure cluster modules implement GenServer behaviour.
  defp require_behaviour(cluster, behaviour) do
    cluster.servers
    |> Enum.uniq
    |> Runtime.require_behaviour(behaviour)
  end

  defp do_intercept_call_request(state, mod, pid, fun, ts) do
    if fun in @call_cast_info do
      do_open_metric(state, mod, pid, fun, ts)
    else
      state
    end
  end

  defp do_intercept_call_response(state, mod, pid, fun, ts) do
    do_close_metric(state, mod, pid, fun, ts)
  end

  # Open partial metric on handle_ function call trace.
  defp do_open_metric(state, mod, pid, fun, ts) do
    metrics =
      Manager.open_summary_metric(state.metrics, mod, pid, fun, ts)
    state = %Monitor{state | metrics: metrics}

    if statistics?(state.cluster) do
      metrics =
        Manager.open_stats_metric(state.metrics, {mod, pid, fun, ts})
      %Monitor{state | metrics: metrics}
    else
      state
    end
  end

  # Close complete metric on handle_ function return trace.
  defp do_close_metric(state, mod, pid, events, ts) do
    metrics = Manager.close_summary_metric(state.metrics, pid, events, ts)
    state = %Monitor{state | metrics: metrics}

    if statistics?(state.cluster) do
      metrics = Manager.close_stats_metric(state.cluster,
        state.metrics, {mod, pid, events, ts})
      %Monitor{state | metrics: metrics}
    else
      state
    end
  end

  # Return interval for monitor window rollover.
  defp window_interval(state) do
    state.cluster.opts[:window_interval] || @window_interval_default
  end

  # Return true if monitor is required to generate optional statistics.
  defp statistics?(cluster), do: cluster.opts[:statistics] || false

  # Return true if monitor is required to trace synchronous calls.
  defp synchronous?(cluster), do: cluster.opts[:synchronous] || false

end
