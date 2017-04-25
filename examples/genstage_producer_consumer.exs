# Usage: mix run examples/genstage_producer_consumer.exs
#
# Hit Ctrl+C twice to stop it.
#
# This basic example demonstrates the collection and
# reporting of metrics data for a simple GenStage pipeline.
# 
# The sample Metrics.Consumer module simply prints the metrics
# data reported by the GenMetrics library to standard out.
#
# The simple GenStage pipeline used in this example is a copy
# of the ProducerConsumer example pipeline found in the
# GenStage project repository:
#
# https://github.com/elixir-lang/gen_stage.
#
defmodule A do
  use GenStage

  def init(counter) do
    {:producer, counter}
  end

  def handle_demand(demand, counter) when demand > 0 do
    events = Enum.to_list(counter..counter+demand-1)
    {:noreply, events, counter + demand}
  end
end

defmodule B do
  use GenStage

  def init(number) do
    {:producer_consumer, number}
  end

  def handle_events(events, _from, number) do
    events =
      for event <- events,
          entry <- event..event+number,
          do: entry
    {:noreply, events, number}
  end
end

defmodule C do
  use GenStage

  def init(:ok) do
    {:consumer, :the_state_does_not_matter}
  end

  def handle_events(_events, _from, state) do
    :timer.sleep(1000)
    {:noreply, [], state}
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
      IO.puts "Metrics-Window: Start:=#{inspect window.start}, Duration=#{inspect window.duration}"
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
                     producer: [A],
                     producer_consumer: [B],
                     consumer: [C],
                     opts: [statistics: true, window_interval: 3000]}

{:ok, _pid} = GenMetrics.monitor_pipeline(pipeline)

#
# Start Sample GenStage ProducerConsumer Pipeline
#
{:ok, a} = GenStage.start_link(A, 0)   # starting from zero
{:ok, b} = GenStage.start_link(B, 2)   # expand by 2
{:ok, c} = GenStage.start_link(C, :ok) # state does not matter

GenStage.sync_subscribe(b, to: a)
GenStage.sync_subscribe(c, to: b)
Process.sleep(:infinity)
