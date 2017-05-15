Code.require_file("stages.exs", "./bench/support")
Application.ensure_all_started(:gen_metrics)
alias GenMetrics.GenStage.Pipeline

{:ok, _sampledp} = SampledProducer.start_link()
{:ok, _sampledc} = SampledConsumer.start_link()

infinite_pipeline = %Pipeline{name: "infinite_pipeline",
                              producer: [SampledProducer],
                              consumer: [SampledConsumer],
                              opts: [statistics: false,
                                     synchronous: true,
                                     sample_rate: 0.05]}

{:ok, _imon} = GenMetrics.monitor_pipeline infinite_pipeline

:observer.start

Benchee.run(%{time: 30, warmup: 5}, %{
      "infinite-sampled-pipeline" => fn ->
              data = %{id: self(), data: String.duplicate("a", 100)}
              stream = Stream.cycle([data])
              for _ <- stream, do: SampledProducer.emit(data)
              receive do
                :benchmark_completed -> :ok
              end

      end})
