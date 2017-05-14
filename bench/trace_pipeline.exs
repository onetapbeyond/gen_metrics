Code.require_file("stages.exs", "./bench/support")
Application.ensure_all_started(:gen_metrics)
alias GenMetrics.GenStage.Pipeline

data = Enum.map(1..500_000, fn i -> %{id: i, data: String.duplicate("a", 100)} end)

{:ok, _untracedp} = UntracedProducer.start_link()
{:ok, _untracedc} = UntracedConsumer.start_link()
{:ok, _tracedp} = TracedProducer.start_link()
{:ok, _tracedc} = TracedConsumer.start_link()

traced_pipeline = %Pipeline{name: "traced_pipeline",
                            producer: [TracedProducer],
                            consumer: [TracedConsumer],
                            opts: [statistics: false,
                                   synchronous: true,
                                   sample_rate: 1.0]}

{:ok, _tmon} = GenMetrics.monitor_pipeline(traced_pipeline)

# :observer.start

Benchee.run(%{time: 30, warmup: 5}, %{
      "1-untraced-pipeline [ repeat 500k msgs N times within ~30s ]" => fn ->
        for %{id: id} = item <- data do
          {:ok, ^id} = UntracedProducer.emit(item)
        end
        for i <- 1..length(data) do
          receive do
            ^i -> :ok
          end
        end
        IO.puts "1-untraced-pipeline 500k msgs completed"
      end,
      "2-traced---pipeline [ repeat 500k msgs N times within ~30s ]" => fn ->
        for %{id: id} = item <- data do
          {:ok, ^id} = TracedProducer.emit(item)
        end
        for i <- 1..length(data) do
          receive do
            ^i -> :ok
          end
        end
        IO.puts "2-traced---pipeline 500k msgs completed"
      end
})
