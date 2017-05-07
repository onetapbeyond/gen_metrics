Code.require_file("server.exs", "./bench/support")
Application.ensure_all_started(:gen_metrics)

data = Enum.map(1..500_000, fn i -> %{id: i, data: String.duplicate("a", 100)} end)

{:ok, _traced} = TracedServer.start_link(length(data))
{:ok, _untraced} = UntracedServer.start_link(length(data))

alias GenMetrics.GenServer.Cluster
cluster = %Cluster{name: "bench_cluster",
                   servers: [TracedServer],
                   opts: [synchronous: false]}
GenMetrics.monitor_cluster(cluster)

Benchee.run(%{time: 30, warmup: 5}, %{
      "untraced-server [ call ]" => fn ->
          UntracedServer.init_state(length(data))
          pid = self()
          for item <- data do
            UntracedServer.do_call(%{item | id: pid})
          end
          receive do
            :benchmark_completed -> :ok
          end
      end,
      "traced---server [ call ]" => fn ->
        TracedServer.init_state(length(data))
        pid = self()
        for item <- data do
          TracedServer.do_call(%{item | id: pid})
        end
        receive do
          :benchmark_completed -> :ok
        end
      end
})
