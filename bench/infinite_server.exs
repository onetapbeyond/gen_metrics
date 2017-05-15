Code.require_file("server.exs", "./bench/support")
Application.ensure_all_started(:gen_metrics)

{:ok, _untraced} = UntracedServer.start_link(99999999999999)
{:ok, _sampled} = SampledServer.start_link(99999999999999)

alias GenMetrics.GenServer.Cluster
cluster = %Cluster{name: "infinite_sampled_server",
                   servers: [SampledServer],
                   opts: [sample_rate: 0.1]}

GenMetrics.monitor_cluster cluster

:observer.start

Benchee.run(%{time: 30, warmup: 5}, %{
      "infinite-sampled-server" => fn ->
              SampledServer.init_state(99999999999999)
              data = %{id: self(), data: String.duplicate("a", 100)}
              stream = Stream.cycle([data])
              for _ <- stream, do: SampledServer.do_call(data)
              receive do
                :benchmark_completed -> :ok
              end
      end})
