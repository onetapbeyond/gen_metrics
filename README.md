[![GitPitch](https://gitpitch.com/assets/badge.svg)](https://gitpitch.com/onetapbeyond/gen_metrics)
[![Hex Version](https://img.shields.io/hexpm/v/gen_metrics.svg "Hex Version")](https://hex.pm/packages/gen_metrics)

# GenMetrics

Runtime metrics for GenServer and GenStage applications.

> Important! This library is not yet suitable for use in production environments. See the [Open Issues](https://github.com/onetapbeyond/gen_metrics/issues) tab for more details.

This library supports the collection and publication of GenServer and GenStage runtime metrics. Metrics data are generated by an introspection agent. No instrumentation is required within the GenServer or GenStage library or within your application source code.

By default, metrics are published by a dedicated GenMetrics reporting process. Any application can subscribe to this process in order to handle metrics data at runtime. Metrics data can also be pushed directly to a `statsd` agent which makes it possible to analyze, and visualize the metrics within existing tools and services like `Graphana` and `Datadog`.

## Quick Look: GenServer Metrics

Given an application with the following GenServers: `Session.Server`, `Logging.Server`, activate metrics collection for the server cluster as follows:

```elixir
alias GenMetrics.GenServer.Cluster
cluster = %Cluster{name: "demo",
                   servers: [Session.Server, Logging.Server],
                   opts: [window_interval: 5000]}
GenMetrics.monitor_cluster(cluster)
```

Metrics are published by a dedicated GenMetrics reporting process. Any application can subscribe to this process in order to receive metrics data. Sample summary metrics data for a GenServer process looks as follows:

```
# Server Name: Demo.Server, PID<0.176.0>

%GenMetrics.GenServer.Summary{name: Demo.Server,
                              pid: #PID<0.176.0>,
                              calls: 8000,
                              casts: 34500,
                              infos: 3333,
                              time_on_calls: 28,
                              time_on_casts: 161,
                              time_on_infos: 15}

# Summary timings measured in milliseconds (ms).
```

Detailed statistical metrics data per process are also available. See the [documentation](https://hexdocs.pm/gen_metrics) for details.

## Quick Look: GenStage Metrics

Given a GenStage application with the following stages: `Data.Producer`, `Data.Scrubber`, `Data.Analyzer` and a `Data.Consumer`, activate metrics collection for the entire pipeline as follows:

```elixir
alias GenMetrics.GenStage.Pipeline
pipeline = %Pipeline{name: "demo",
                     producer: [Data.Producer],
                     producer_consumer: [Data.Scrubber, Data.Analyzer],
                     consumer: [Data.Consumer]}
GenMetrics.monitor_pipeline(pipeline)
```

Metrics are published by a dedicated GenMetrics reporting process. Any application can subscribe to this process in order to receive metrics data. Sample summary metrics data for a GenStage process looks as follows:

```
# Stage Name: Data.Producer, PID<0.195.0>

%GenMetrics.GenStage.Summary{stage: Data.Producer,
                             pid: #PID<0.195.0>,
                             callbacks: 9536,
                             time_on_callbacks: 407,
                             demand: 4768000,
                             events: 4768000}

# Summary timings measured in milliseconds (ms).
```

Detailed statistical metrics data per process are also available. See the [documentation](https://hexdocs.pm/gen_metrics) for details.

## Quick Look: Metrics Reporting

Redirect your GenServer cluster metrics data to the Datadog service as follows:

```elixir
alias GenMetrics.GenServer.Cluster
cluster = %Cluster{name: "demo",
                   servers: [Session.Server, Logging.Server],
                   opts: [statistics: :datadog]}
GenMetrics.monitor_cluster(cluster)
```

Redirect your GenStage pipeline metrics data to a `statsd` agent as follows:

```
alias GenMetrics.GenStage.Pipeline
pipeline = %Pipeline{name: "demo",
                     producer: [Data.Producer],
                     producer_consumer: [Data.Scrubber, Data.Analyzer],
                     consumer: [Data.Consumer],
                     opts: [statistics: :statsd]}
GenMetrics.monitor_pipeline(pipeline)
```

## Documentation

Find detailed documentation for the GenMetrics library on [HexDocs](https://hexdocs.pm/gen_metrics).

## Installation

GenStage requires Elixir v1.4. Just add `:gen_metrics` to your list of dependencies in mix.exs:

```elixir
def deps do
  [{:gen_metrics, "~> 0.2.0"}]
end
```

## Examples

Examples using GenMetrics to collect and report runtime metrics for GenServer applications can be found in the [examples](examples) directory:

  * [genserver_events](examples/genserver_events.exs)

Examples using GenMetrics to collect and report runtime metrics for GenStage applications can also be found in the [examples](examples) directory:

  * [genstage_producer_consumer](examples/genstage_producer_consumer.exs)

  * [genstage_gen_event](examples/genstage_gen_event.exs)

  * [genstage_rate_limiter](examples/genstage_rate_limiter.exs)

All of these GenStage example applications are clones of the example applications provided in the [GenStage](http://github.com/elixir-lang/gen_stage) project repository.


## Benchmarks

Some of you may be curious about the performance impact `gen_metrics` has on the servers and pipelines it is observing, so we've put together a couple of benchmarks to compare the overhead of traced vs untraced servers and pipelines. You can tweak and run the benchmark yourself under `bench/bench.exs`, and simply run `mix bench` to execute them.

The most recent run of the benchmark produced the following report. This benchmark was run on a 2016 Macbook Pro (2.5ghz i7, 16GB RAM, SSD):

```
Elixir 1.4.1
Erlang 19.2
Benchmark suite executing with the following configuration:
warmup: 5.0s
time: 30.0s
parallel: 1
inputs: none specified
Estimated total run time: 140.0s

Benchmarking traced pipeline...
Benchmarking traced server (call)...
Benchmarking untraced pipeline...
Benchmarking untraced server (call)...

Name                             ips        average  deviation         median
untraced server (call)          0.30         3.33 s    ±12.65%         3.08 s
traced server (call)           0.140         7.16 s     ±8.54%         7.31 s
untraced pipeline             0.0722        13.84 s     ±8.75%        14.16 s
traced pipeline               0.0428        23.37 s     ±1.27%        23.37 s

Comparison:
untraced server (call)          0.30
traced server (call)           0.140 - 2.15x slower
untraced pipeline             0.0722 - 4.16x slower
traced pipeline               0.0428 - 7.02x slower
```

While the benchmark *is* a contrived scenario (pushing 1M large messages through a `GenServer`, then the same through a `GenStage` pipeline),
it should reflect a general idea of what you can expect from a performance perspective.

## License

See the [LICENSE](LICENSE) file for license rights and limitations (Apache License 2.0).
