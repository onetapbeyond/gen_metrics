defmodule GenMetrics.Reporter do
  use GenStage

  @moduledoc false

  def start_link(name) do
    GenStage.start_link(__MODULE__, 0, name: name)
  end

  def push(reporter, window) do
    GenStage.cast(reporter, {:monitor_metrics, window})
  end

  def init(state) do
    {:producer, state, dispatcher: GenStage.BroadcastDispatcher}
  end

  def handle_subscribe(_, _, _, state) do
    {:automatic, state + 1}
  end

  def handle_cancel(_, _, state) do
    {:noreply, [], max(state - 1, 0)}
  end

  def handle_cast({:monitor_metrics, window}, subscriber_count) do
    if subscriber_count == 0 do
      {:noreply, [], subscriber_count}
    else
      {:noreply, [window], subscriber_count}
    end
  end

  def handle_demand(_demand, state) do
    {:noreply, [], state}
  end

end
