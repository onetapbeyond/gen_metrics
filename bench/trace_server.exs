Code.require_file("server.exs", "./bench/support")
Application.ensure_all_started(:gen_metrics)

data = Enum.map(1..500_000, fn i -> %{id: i, data: String.duplicate("a", 100)} end)

{:ok, _untraced} = UntracedServer.start_link(length(data))
{:ok, _traced}   = TracedServer.start_link(length(data))

alias GenMetrics.GenServer.Cluster
traced_cluster = %Cluster{name: "traced_cluster",
                          servers: [TracedServer],
                          opts: [statistics: false,
                                 sample_rate: 1.0,
                                 synchronous: true]}

{:ok, _tmon} = GenMetrics.monitor_cluster(traced_cluster)

# :observer.start

Benchee.run(%{time: 30, warmup: 5}, %{
      "1-untraced-server [ repeat 500k callbacks N times within ~30s ]" => fn ->
          UntracedServer.init_state(length(data))
          pid = self()
          for item <- data do
            UntracedServer.do_call(%{item | id: pid})
          end
          receive do
            :benchmark_completed -> :ok
          end
          IO.puts "1-untraced-server 500k callbacks completed"
      end,
      "2-traced---server [ repeat 500k callbacks N times within ~30s ]" => fn ->
        TracedServer.init_state(length(data))
        pid = self()
        for item <- data do
          TracedServer.do_call(%{item | id: pid})
        end
        receive do
          :benchmark_completed -> :ok
        end
        IO.puts "2-traced--server 500k callbacks completed"
      end
})
