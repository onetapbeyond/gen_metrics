Code.require_file("stages.exs", "./bench/support")
Application.ensure_all_started(:gen_metrics)
alias GenMetrics.GenStage.Pipeline

data = Enum.map(1..500_000, fn i -> %{id: i, data: String.duplicate("a", 100)} end)

{:ok, _untracedp} = UntracedProducer.start_link()
{:ok, _untracedc} = UntracedConsumer.start_link()
{:ok, _sampledp} = SampledProducer.start_link()
{:ok, _sampledc} = SampledConsumer.start_link()

sampled_pipeline = %Pipeline{name: "traced_pipeline",
                             producer: [SampledProducer],
                             consumer: [SampledConsumer],
                             opts: [statistics: false,
                                    synchronous: true,
                                    sample_rate: 0.1]}

{:ok, _smon} = GenMetrics.monitor_pipeline(sampled_pipeline)

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
      "2-sampled--pipeline [ repeat 500k msgs N times within ~30s ]" => fn ->
        for %{id: id} = item <- data do
          {:ok, ^id} = SampledProducer.emit(item)
        end
        for i <- 1..length(data) do
          receive do
            ^i -> :ok
          end
        end
        IO.puts "2-sampled--pipeline 500k msgs completed"
      end
})
