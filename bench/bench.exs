Code.require_file("server.exs", "./bench/support")
Code.require_file("stages.exs", "./bench/support")
Application.ensure_all_started(:gen_metrics)

data = Enum.map(1..1_000_000, fn i -> %{id: i, data: String.duplicate("a", 100)} end)

{:ok, _traced} = TracedServer.start_link()
{:ok, _untraced} = UntracedServer.start_link()

alias GenMetrics.GenServer.Cluster
cluster = %Cluster{name: "bench",
                   servers: [TracedServer],
                   opts: [window_interval: 1000]}
GenMetrics.monitor_cluster(cluster)

{:ok, _tracedp} = TracedProducer.start_link()
{:ok, _tracedc} = TracedConsumer.start_link()
{:ok, _untracedp} = UntracedProducer.start_link()
{:ok, _untracedc} = UntracedConsumer.start_link()

alias GenMetrics.GenStage.Pipeline
pipeline = %Pipeline{name: "bench2",
                     producer: [TracedProducer],
                     consumer: [TracedConsumer],
                     opts: [statistics: true]}

{:ok, _pid} = GenMetrics.monitor_pipeline(pipeline)

Benchee.run(%{time: 30, warmup: 5}, %{
      "untraced server (call)" => fn ->
          for %{id: id} = item <- data do
            {:ok, ^id} = UntracedServer.do_call(item)
          end
      end,
      "traced server (call)" => fn ->
        for %{id: id} = item <- data do
          {:ok, ^id} = TracedServer.do_call(item)
        end
      end,
      "untraced pipeline" => fn ->
        for %{id: id} = item <- data do
          {:ok, ^id} = UntracedProducer.emit(item)
        end
        for i <- 1..length(data) do
          receive do
            ^i -> :ok
          end
        end
      end,
      "traced pipeline" => fn ->
        for %{id: id} = item <- data do
          {:ok, ^id} = TracedProducer.emit(item)
        end
        for i <- 1..length(data) do
          receive do
            ^i -> :ok
          end
        end
      end
})
