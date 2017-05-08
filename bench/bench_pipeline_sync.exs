Code.require_file("stages_serial_demand.exs", "./bench/support")
Code.require_file("stages_batched_demand.exs", "./bench/support")
Application.ensure_all_started(:gen_metrics)
alias GenMetrics.GenStage.Pipeline

data = Enum.map(1..1_000_000, fn i -> %{id: i, data: String.duplicate("a", 100)} end)

{:ok, _tracedsp} = TracedSerialProducer.start_link()
{:ok, _tracedsc} = TracedSerialConsumer.start_link()
{:ok, _untracedsp} = UntracedSerialProducer.start_link()
{:ok, _untracedsc} = UntracedSerialConsumer.start_link()

serial_pipeline = %Pipeline{name: "bench_serial_pipeline",
                            producer: [TracedSerialProducer],
                            consumer: [TracedSerialConsumer],
                            opts: [statistics: false, synchronous: true]}

{:ok, _pids} = GenMetrics.monitor_pipeline(serial_pipeline)

{:ok, _tracedbp} = TracedBatchedProducer.start_link()
{:ok, _tracedbc} = TracedBatchedConsumer.start_link()
{:ok, _untracedbp} = UntracedBatchedProducer.start_link()
{:ok, _untracedbc} = UntracedBatchedConsumer.start_link()

batched_pipeline = %Pipeline{name: "bench_batched_pipeline",
                             producer: [TracedBatchedProducer],
                             consumer: [TracedBatchedConsumer],
                             opts: [statistics: false, synchronous: true]}

{:ok, _pidb} = GenMetrics.monitor_pipeline(batched_pipeline)

Benchee.run(%{time: 30, warmup: 5}, %{
      "untraced-pipeline [max_demand:    1]" => fn ->
        for %{id: id} = item <- data do
          {:ok, ^id} = UntracedSerialProducer.emit(item)
        end
        for i <- 1..length(data) do
          receive do
            ^i -> :ok
          end
        end
      end,
      "traced---pipeline [max_demand:    1]" => fn ->
        for %{id: id} = item <- data do
          {:ok, ^id} = TracedSerialProducer.emit(item)
        end
        for i <- 1..length(data) do
          receive do
            ^i -> :ok
          end
        end
      end,
      "untraced-pipeline [max_demand: 1000]" => fn ->
        for %{id: id} = item <- data do
          {:ok, ^id} = UntracedBatchedProducer.emit(item)
        end
        for i <- 1..length(data) do
          receive do
            ^i -> :ok
          end
        end
      end,
      "traced---pipeline [max_demand: 1000]" => fn ->
        for %{id: id} = item <- data do
          {:ok, ^id} = TracedBatchedProducer.emit(item)
        end
        for i <- 1..length(data) do
          receive do
            ^i -> :ok
          end
        end
      end
})
