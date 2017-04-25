# Usage: mix run examples/genstage_rate_limiter.exs
#
# Hit Ctrl+C twice to stop it.
#
# This example demonstrates the collection and reporting of
# metrics data for a GenStage pipeline implemented to enforce
# rate limiting work on a consumer.
#
# The sample Metrics.Consumer module simply prints the metrics
# data reported by the GenMetics library to standard out.
#
# The GenStage pipeline used in this example is a copy of the
# RateLimiter example pipeline found in the GenStage project repo:
#
# https://github.com/elixir-lang/gen_stage.
#
defmodule Producer do
  use GenStage

  def init(counter) do
    {:producer, counter}
  end

  def handle_demand(demand, counter) when demand > 0 do
    events = Enum.to_list(counter..counter+demand-1)
    {:noreply, events, counter + demand}
  end
end

defmodule RateLimiter do
  use GenStage

  def init(_) do
    {:consumer, %{}}
  end

  def handle_subscribe(:producer, opts, from, producers) do
    pending = opts[:max_demand] || 1000
    interval = opts[:interval] || 5000
    producers = Map.put(producers, from, {pending, interval})
    producers = ask_and_schedule(producers, from)
    {:manual, producers}
  end

  def handle_cancel(_, from, producers) do
    {:noreply, [], Map.delete(producers, from)}
  end

  def handle_events(events, from, producers) do
    producers = Map.update!(producers, from, fn {pending, interval} ->
      {pending + length(events), interval}
    end)
    {:noreply, [], producers}
  end

  def handle_info({:ask, from}, producers) do
    {:noreply, [], ask_and_schedule(producers, from)}
  end

  defp ask_and_schedule(producers, from) do
    case producers do
      %{^from => {pending, interval}} ->
        GenStage.ask(from, pending)
        Process.send_after(self(), {:ask, from}, interval)
        Map.put(producers, from, {0, interval})
      %{} ->
        producers
    end
  end
end

defmodule Metrics.Consumer do
    use GenStage

    def start_link do
        GenStage.start_link(__MODULE__, [])
    end

    def init(_state) do
      {:consumer, :state_does_not_matter,
       subscribe_to: [{GenMetrics.GenStage.Reporter, max_demand: 1}]}
    end

    def handle_events([window | _], _from, state) do
      IO.puts "\n\nGenStage Pipeline: #{inspect window.pipeline.name}"
      IO.puts "Metrics-Window: Start:=#{inspect window.start},Duration=#{inspect window.duration}"
      IO.puts "Summary Metrics"
      for summary <- window.summary do
        IO.puts "#{inspect summary}"
      end
      IO.puts "Statistical Metrics"
      for stage <- window.stats do
        IO.puts "Stage:=#{inspect stage.name} [ #{inspect stage.pid} ]"
        IO.puts "Demand:=#{inspect stage.demand}"
        IO.puts "Events:=#{inspect stage.events}"
        IO.puts "Timings:=#{inspect stage.timings}"
      end
      IO.puts "\n"
      {:noreply, [], state}
    end
end

#
# Initialize GenMetrics Monitoring for GenStage Pipeline
#
alias GenMetrics.GenStage.Pipeline

Application.start(GenMetrics.Application)
Metrics.Consumer.start_link

pipeline = %Pipeline{name: "demo",
                     producer: [Producer],
                     consumer: [RateLimiter],
                     opts: [statistics: true, window_interval: 2000]}

{:ok, _pid} = GenMetrics.monitor_pipeline(pipeline)

#
# Start Sample GenStage RateLimiter Pipeline
#
{:ok, a} = GenStage.start_link(Producer, 0)      # starting from zero
{:ok, b} = GenStage.start_link(RateLimiter, :ok) # expand by 2
GenStage.sync_subscribe(b, to: a, max_demand: 10, interval: 2000)
Process.sleep(:infinity)
