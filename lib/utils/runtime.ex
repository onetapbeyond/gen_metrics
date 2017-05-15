defmodule GenMetrics.Utils.Runtime do

  @window_interval_default 1000
  @sample_rate_default 1.0

  @moduledoc false

  @doc """
  Verify modules are compiled and loaded.

  Returns an empty list if all modules are 
  successfully compiled and loaded.

  Returns a non-empty list of error messages describing
  each module that fails to compile or load.
  """
  @spec require_modules([module]) :: [String.t]
  def require_modules(module_list) do
    module_list
    |> Enum.uniq
    |> Enum.reduce([], fn(module, acc) ->
      try do
        Code.eval_string("require #{inspect module}")
        acc
      rescue
        _ -> ["Module #{inspect module} not loaded and could not be found." | acc]
      end
    end)
  end

  @doc """
  Verify modules implement a required behaviour.

  Returns an empty list if all modules successfully
  implement the required behaviour.

  Returns a non-empty list of error messages describing
  each module that fails to implement the required behaviour.
  """
  @spec require_behaviour([module], module) :: [String.t]
  def require_behaviour(module_list, behaviour) do
    module_list
    |> Enum.uniq
    |> Enum.reduce([], fn(module, acc) ->
      try do
        attrs = apply(module, :__info__, [:attributes])
        behaviours = get_in(attrs, [:behaviour])
        if behaviour in behaviours do
          acc
        else
          ["Module #{inspect module} does not implement #{inspect behaviour}." | acc]
        end
      rescue
        _ -> ["Module #{inspect module} does not implement #{inspect behaviour}." | acc]
      end
    end)
  end

  # Return interval for monitor window rollover.
  def window_interval(monitor) do
    window_interval = monitor.opts[:window_interval] || @window_interval_default
    round(window_interval)
  end

  # Return interval for sampling within window.
  def sample_interval(monitor) do
    window_interval =
      monitor.opts[:window_interval] || @window_interval_default
    sample_interval = round(window_interval * sample_rate(monitor))
    if sample_interval == window_interval do
      # adjust sample interval to fit inside window_interval
      round(sample_interval * 0.90)
    else
      round(sample_interval)
    end
  end

  # Return active metrics sampling rate.
  def sample_rate(monitor) do
    if sampling?(monitor) do
      sample_rate = monitor.opts[:sample_rate]
      if sample_rate > 0.9 do
        # Enforce upper limit on sampling rate. Rate must
        # be either 1.0 (no sampling) or <= 0.9.
        0.9
      else
        sample_rate
      end
    else
      @sample_rate_default
    end
  end

  # Return true if sampling rate below 1.0 in use.
  def sampling?(monitor) do
    sample_rate = monitor.opts[:sample_rate]
    if sample_rate == nil || sample_rate == 1.0 do
      false
    else
      true
    end
  end

  # Return true if monitor is required to generate optional statistics.
  def statistics?(monitor), do: monitor.opts[:statistics] || false

  # Return true if monitor is required to trace synchronous calls.
  def synchronous?(monitor), do: monitor.opts[:synchronous] || true

  def safe_div(0, _), do: 0
  def safe_div(num, d), do: div(num, d)

  def micro_to_milli(0), do: 0
  def micro_to_milli(milli), do: safe_div(milli, 1000)

  def nano_to_micro(0), do: 0
  def nano_to_micro(nano), do: safe_div(nano, 1000)
  def nano_to_milli(0), do: 0
  def nano_to_milli(nano), do: safe_div(nano, 1_000_000)

end
