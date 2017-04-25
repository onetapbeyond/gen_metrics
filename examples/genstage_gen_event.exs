# Usage: mix run examples/genstage_gen_event.exs
#
# This example demonstrates the collection and reporting of
# metrics data for a GenStage pipeline implemented as a
# replacement for GenEvent.
#
# The sample Metrics.Consumer module simply prints the metrics
# data reported by the GenMetics library to standard out.
#
# The GenStage pipeline used in this example is a copy of the
# GenEvent example pipeline found in the GenStage project repo:
#
# https://github.com/elixir-lang/gen_stage.
#
defmodule Broadcaster do
  use GenStage

  def start_link() do
    GenStage.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def sync_notify(event, timeout \\ 5000) do
    GenStage.call(__MODULE__, {:notify, event}, timeout)
  end

  def init(:ok) do
    {:producer, {:queue.new, 0}, dispatcher: GenStage.BroadcastDispatcher}
  end

  def handle_call({:notify, event}, from, {queue, demand}) do
    dispatch_events(:queue.in({from, event}, queue), demand, [])
  end

  def handle_demand(incoming_demand, {queue, demand}) do
    dispatch_events(queue, incoming_demand + demand, [])
  end

  defp dispatch_events(queue, demand, events) do
    with d when d > 0 <- demand,
         {{:value, {from, event}}, queue} <- :queue.out(queue) do
      GenStage.reply(from, :ok)
      dispatch_events(queue, demand - 1, [event | events])
    else
      _ -> {:noreply, Enum.reverse(events), {queue, demand}}
    end
  end
end

defmodule Consumer do
  use GenStage

  def start_link() do
    GenStage.start_link(__MODULE__, :ok)
  end

  def init(:ok) do
    {:consumer, :ok, subscribe_to: [Broadcaster]}
  end

  def handle_events(_events, _from, state) do
    {:noreply, [], state}
  end
end

defmodule App do

  def start do
    import Supervisor.Spec

    children = [
      worker(Broadcaster, []),
      worker(Consumer, [], id: 1),
      worker(Consumer, [], id: 2),
      worker(Consumer, [], id: 3),
      worker(Consumer, [], id: 4)
    ]

    Supervisor.start_link(children, strategy: :one_for_one)
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
                     producer: [Broadcaster],
                     consumer: [Consumer],
                     opts: [statistics: true]}

{:ok, _pid} = GenMetrics.monitor_pipeline(pipeline)

#
# Start Sample GenStage GenEvent-Replacement Pipeline
#
App.start
Broadcaster.sync_notify(1)
Broadcaster.sync_notify(2)
Broadcaster.sync_notify(3)
Broadcaster.sync_notify(4)
Broadcaster.sync_notify(5)
Process.sleep(2000)
