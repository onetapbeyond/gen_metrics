defmodule GenMetrics.GenStage.Monitor do
  use GenServer
  alias GenMetrics.GenStage.Manager
  alias GenMetrics.GenStage.Monitor
  alias GenMetrics.GenStage.Pipeline
  alias GenMetrics.GenStage.Window
  alias GenMetrics.Reporter
  alias GenMetrics.Utils.Runtime

  @moduledoc false
  @handle_demand :handle_demand
  @handle_events :handle_events
  @handle_call   :handle_call
  @handle_cast   :handle_cast

  defstruct pipeline: %Pipeline{}, metrics: nil, start: 0, duration: 0

  def start_link(pipeline) do
    GenServer.start_link(__MODULE__, pipeline)
  end

  def init(pipeline) do
    with {:ok, _}     <- validate_modules(pipeline),
         {:ok, _}     <- validate_behaviours(pipeline),
         {:ok, _}     <- activate_tracing(pipeline),
         state        <- initialize_monitor(pipeline),
      do: start_monitor(state)
  end

  #
  # Handlers for intercepting :erlang.trace/3 and :erlang.trace_pattern/2
  # callbacks for modules registered on the pipeline.
  #

  def handle_info({:trace_ts, pid, :call, {mod, fun, [demand | _]}, ts}, state) do
    {:noreply,
     do_intercept_call_request(state, pid, {mod, fun}, demand, ts)}
  end

  # Intercept {:noreply, [event], new_state} response.
  def handle_info({:trace_ts, pid, :return_from, {mod, _, _},
                   {:noreply, events, _}, ts}, state) do
    {:noreply,
     do_intercept_call_response(state, mod, pid, length(events), ts)}
  end

  # Intercept {:noreply, [event], new_state, :hibernate} response.
  def handle_info({:trace_ts, pid, :return_from, {mod, _, _},
                   {:noreply, events, _, _}, ts}, state) do
    {:noreply,
     do_intercept_call_response(state, mod, pid, length(events), ts)}
  end

  # Intercept {:reply, _reply, [event], new_state} response.
  def handle_info({:trace_ts, pid, :return_from, {mod, _, _},
                   {:reply, _, events, _}, ts}, state) do
    {:noreply,
     do_intercept_call_response(state, mod, pid, length(events), ts)}
  end

  # Intercept {:reply, _reply, [event], new_state, :hibernate} response.
  def handle_info({:trace_ts, pid, :return_from, {mod, _, _},
                   {:noreply, _, events, _, _}, ts}, state) do
    {:noreply,
     do_intercept_call_response(state, mod, pid, length(events), ts)}
  end

  # Intercept {:stop, reason, new_state} response.
  def handle_info({:trace_ts, pid, :return_from, {mod, _, _},
                   {:stop, _, _}, ts}, state) do
    {:noreply,
     do_intercept_call_response(state, mod, pid, 0, ts)}
  end

  # Report and rollover metrics window.
  def handle_info(:rollover_metrics_window, state) do
    now = :erlang.system_time
    state = %Monitor{state | duration: Runtime.nano_to_milli(now - state.start)}
    window = Manager.as_window(state.metrics,
      Runtime.statistics?(state.pipeline), Runtime.sample_rate(state.pipeline))
    window = %Window{window | pipeline: state.pipeline,
                     start: state.start, duration: state.duration}
    Reporter.push(GenMetrics.GenStage.Reporter, window)
    Process.send_after(self(),
      :rollover_metrics_window, Runtime.window_interval(state.pipeline))
    if Runtime.sampling?(state.pipeline) do
      activate_tracing(state.pipeline)
      Process.send_after(self(),
        :silence_metrics_window, Runtime.sample_interval(state.pipeline))
    end
    {:noreply, initialize_monitor(state.pipeline, state.metrics)}
  end

  # Sampling window is closed for current metrics windows
  # so temporarily silence tracing.
  def handle_info(:silence_metrics_window, state) do
    activate_tracing(state.pipeline, true)
    {:noreply, state}
  end

  # Catch-all for calls not intercepted by monitor.
  def handle_info(_msg, state), do: {:noreply, state}

  #
  # Private utility functions follow.
  #

  # Initialize GenServer state for monitor.
  defp initialize_monitor(pipeline, metrics \\ nil)  do
    if metrics do
      %Monitor{pipeline: pipeline,
               metrics: Manager.reinitialize(metrics),
               start: :erlang.system_time}
    else
        %Monitor{pipeline: pipeline,
                 metrics: Manager.initialize(),
                 start: :erlang.system_time}
    end
  end

  # Initialize periodic callback for metrics reporting and window rollover.
  defp start_monitor(state) do
    Process.send_after(self(),
      :rollover_metrics_window, Runtime.window_interval(state.pipeline))
    if Runtime.sampling?(state.pipeline) do
      Process.send_after(self(),
        :silence_metrics_window, Runtime.sample_interval(state.pipeline))
    end
    {:ok, state}
  end

  # Activate tracing for stages within pipeline.
  defp activate_tracing(pipeline, silent \\ false) do

    if silent do
      :erlang.trace(:processes, false, [:call, :monotonic_timestamp])
    else
      :erlang.trace(:processes, true, [:call, :monotonic_timestamp])

      for pmod <- pipeline.producer do
        :erlang.trace_pattern({pmod, :handle_demand, 2},
          [{:_, [], [{:return_trace}]}])
        :erlang.trace_pattern({pmod, :handle_cast, 2},
          [{:_, [], [{:return_trace}]}])
        if Runtime.synchronous?(pipeline) do
          :erlang.trace_pattern({pmod, :handle_call, 3},
            [{:_, [], [{:return_trace}]}])
        end
      end

      for pcmod <- pipeline.producer_consumer do
        :erlang.trace_pattern({pcmod, :handle_events, 3},
          [{:_, [], [{:return_trace}]}])
        :erlang.trace_pattern({pcmod, :handle_cast, 2},
          [{:_, [], [{:return_trace}]}])
        if Runtime.synchronous?(pipeline) do
          :erlang.trace_pattern({pcmod, :handle_call, 3},
            [{:_, [], [{:return_trace}]}])
        end
      end

      for cmod <- pipeline.consumer do
        :erlang.trace_pattern({cmod, :handle_events, 3},
          [{:_, [], [{:return_trace}]}])
      end
    end

    {:ok, pipeline}
  end

  # Validate pipeline modules can be loaded or report failures.
  defp validate_modules(pipeline) do
    case require_modules(pipeline) do
      []   -> {:ok, pipeline}
      errs -> {:stop, {:bad_pipeline, errs}}
    end
  end

  # Ensure pipeline modules are available and can be loaded.
  defp require_modules(pipeline) do
    [pipeline.producer, pipeline.producer_consumer, pipeline.consumer]
    |> Enum.flat_map(fn(modules) -> modules end)
    |> Enum.uniq
    |> Runtime.require_modules
  end

  # Validate pipeline modules implement GenStage or report failures.
  defp validate_behaviours(pipeline) do
    case require_behaviour(pipeline, GenStage) do
      []   -> {:ok, pipeline}
      errs -> {:stop, {:bad_pipeline, errs}}
    end
  end

  # Ensure pipeline modules implement GenStage behaviour.
  defp require_behaviour(pipeline, behaviour) do
    [pipeline.producer, pipeline.producer_consumer, pipeline.consumer]
    |> Enum.flat_map(fn(modules) -> modules end)
    |> Enum.uniq
    |> Runtime.require_behaviour(behaviour)
  end

  defp do_intercept_call_request(state, pid, {mod, fun}, demand, ts) do
    case fun do
      @handle_demand -> do_open_metric(state, mod, pid, demand, ts)
      @handle_events -> do_open_metric(state, mod, pid, length(demand), ts)
      @handle_call   -> do_open_metric(state, mod, pid, 0, ts)
      @handle_cast   -> do_open_metric(state, mod, pid, 0, ts)
      _ -> state
    end
  end

  defp do_intercept_call_response(state, mod, pid, events, ts) do
    do_close_metric(state, mod, pid, events, ts)
  end

  # Open partial metric on handle_ function call trace.
  defp do_open_metric(state, mod, pid, demand, ts) do
    metrics =
      Manager.open_summary_metric(state.metrics, mod, pid, demand, ts)
    state = %Monitor{state | metrics: metrics}

    if Runtime.statistics?(state.pipeline) do
      metrics =
        Manager.open_stats_metric(state.metrics, {mod, pid, demand, ts})
      %Monitor{state | metrics: metrics}
    else
      state
    end
  end

  # Close complete metric on handle_ function return trace.
  defp do_close_metric(state, mod, pid, events, ts) do
    metrics = Manager.close_summary_metric(state.metrics, mod, pid, events, ts)
    state = %Monitor{state | metrics: metrics}

    if Runtime.statistics?(state.pipeline) do
      metrics = Manager.close_stats_metric(state.pipeline,
        state.metrics, {mod, pid, events, ts})
      %Monitor{state | metrics: metrics}
    else
      state
    end
  end

end
