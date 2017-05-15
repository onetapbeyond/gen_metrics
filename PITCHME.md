## GenMetrics

<span style="color:gray">Elixir GenServer and GenStage Runtime Metrics</span>

Note:
Provide brief background, then state agenda: GenSever + GenStage
behaviours and realtime metrics collection and reporting by GenMetrics.

---

### Application Runtime Metrics

- Summary Metrics
- Plus optional Statistical Metrics
- Delivered In-Memory, Or To STATSD Agent
- For any GenServer or GenStage Application
- Without requiring changes to existing code <!-- .element: class="fragment" -->

Note:
Introduce GenServer, GenStage behaviours on OTP. Emphasize metrics
by introspection.

---

### Hex Package Dependency

```elixir
def deps do
  [{:gen_metrics, "~> 0.3.0"}]
end
```

Note:
Mention detailed HexDocs documentation available on hexdocs.pm.

---

### GenServer Metrics

+++

#### GenServer Metrics Per Server Process

- Number of `call`, `cast`, and `info` callbacks
- Time taken on these callbacks
- Plus optional detailed statistical metrics

Note:
Explain that *callbacks* are the *unit-of-work* in a GenServer.
Also elaborate on differences between summary and statistical metrics.

+++

#### GenMetrics Activation

```elixir
alias GenMetrics.GenServer.Cluster

cluster = %Cluster{name: "demo",
                   servers: [Session.Server, Logging.Server]}

GenMetrics.monitor_cluster(cluster)

# Here Session.Server and Logging.Server are example GenServers.
```

Note:
Point out that GenMetrics provides it's own supervision tree.

+++

#### GenMetrics Sampling

```elixir
alias GenMetrics.GenServer.Cluster

cluster = %Cluster{name: "demo",
                   servers: [Session.Server, Logging.Server],
                   opts: [sample_rate: 0.2]}

GenMetrics.monitor_cluster(cluster)

# Here Session.Server and Logging.Server are example GenServers.
```

Note:
Sampling reduces runtime overhead of GenMetrics monitoring agent.

+++

#### GenServer Summary Metrics

#### Sample Metrics Data

```elixir
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

Note:
Provide example by explaining how *calls* and *time_on_calls* relate.
+++

#### GenServer Statistical Metrics

#### Optional Statsd Activation

```elixir
alias GenMetrics.GenServer.Cluster

cluster = %Cluster{name: "demo",
                   servers: [Session.Server, Logging.Server],
                   opts: [statistics: :statsd]}

GenMetrics.monitor_cluster(cluster)

# Here Session.Server and Logging.Server are example GenServers.
```

Note:
Explain `:statsd` integration with analysis and visualization
tools such as Grafana and Datadog.

+++

#### GenServer Statistical Metrics

#### Optional Datadog Activation

```elixir
alias GenMetrics.GenServer.Cluster

cluster = %Cluster{name: "demo",
                   servers: [Session.Server, Logging.Server],
                   opts: [statistics: :datadog]}

GenMetrics.monitor_cluster(cluster)

# Here Session.Server and Logging.Server are example GenServers.
```

Note:
Mention `:datadog` tagging feature is automatically activated
to support filtering on individual GenServer clusters.

+++

#### GenServer Statistical Metrics

#### Optional In-Memory Activation

```elixir
alias GenMetrics.GenServer.Cluster

cluster = %Cluster{name: "demo",
                   servers: [Session.Server, Logging.Server],
                   opts: [statistics: true]}

GenMetrics.monitor_cluster(cluster)

# Here Session.Server and Logging.Server are example GenServers.
```

Note:
Mention additional *opts* such as *window_interval* and how it works.

+++

#### GenServer Statistical Metrics

#### Sample In-Memory Metrics Data

```elixir
# Server Name: Demo.Server, PID<0.176.0>

# handle_call/3
%GenMetrics.GenServer.Stats{callbacks: 8000,
                            max: 149,
                            mean: 3,
                            min: 2,
                            range: 147,
                            stdev: 2,
                            total: 25753}

# Statistical timings measured in microseconds (µs).
```

Note:
Briefly explain how `in-memory` statistical metrics are captured
and calculated. Recommend judicious use.

+++

#### GenServer Statistical Metrics

#### Sample In-Memory Metrics Data

```elixir
# Server Name: Demo.Server, PID<0.176.0>

# handle_cast/2
%GenMetrics.GenServer.Stats{callbacks: 34500,
                            max: 3368,
                            mean: 4,
                            min: 2,
                            range: 3366,
                            stdev: 31,
                            total: 141383}

# Statistical timings measured in microseconds (µs).
```

+++

#### GenServer Statistical Metrics

#### Sample In-Memory Metrics Data

```elixir
# Server Name: Demo.Server, PID<0.176.0>

# handle_info/2
%GenMetrics.GenServer.Stats{callbacks: 3333,
                            max: 37,
                            mean: 4,
                            min: 2,
                            range: 35,
                            stdev: 2,
                            total: 13510}

# Statistical timings measured in microseconds (µs).
```

---

### GenStage Metrics

+++

#### GenStage Metrics Per Stage Process

- Number of `demand` and `events` callbacks
- Time taken on these callbacks
- Size of upstream demand
- Size of events emitted to meet demand
- Plus optional detailed statistical metrics

Note:
Briefly discuss GenStage demand, events and back-pressure.

+++

#### GenStage Activation

```elixir
alias GenMetrics.GenStage.Pipeline

pipeline = %Pipeline{name: "demo",
                     producer: [Data.Producer],
                     producer_consumer:
                     [Data.Scrubber, Data.Analyzer],
                     consumer: [Data.Consumer]}

GenMetrics.monitor_pipeline(pipeline)

# Here Data.* are simply example GenStages.
```

Note:
Mention GenMetrics monitoring supports both complete and
partial pipelines.

#### GenStage Sampling

```elixir
alias GenMetrics.GenStage.Pipeline

pipeline = %Pipeline{name: "demo",
                     producer: [Data.Producer],
                     producer_consumer:
                     [Data.Scrubber, Data.Analyzer],
                     consumer: [Data.Consumer],
                     opts: [sample_rate: 0.1]}

GenMetrics.monitor_pipeline(pipeline)

# Here Data.* are simply example GenStages.
```

Note:
Sampling reduces runtime overhead of the GenMetrics monitoring agent.

+++

#### GenStage Summary Metrics

#### Sample Metrics Data

```elixir
# Stage Name: Data.Producer, PID<0.195.0>

%GenMetrics.GenStage.Summary{stage: Data.Producer,
                             pid: #PID<0.195.0>,
                             callbacks: 9536,
                             time_on_callbacks: 407,
                             demand: 4768000,
                             events: 4768000}

# Summary timings measured in milliseconds (ms).
```

Note:
Explain *callbacks*, *demand*, and *events* concepts and
how they are reflected in the metrics data shown.

++++

#### GenStage Statistical Metrics

#### Optional Statsd Activation

```elixir
alias GenMetrics.GenStage.Pipeline

pipeline = %Pipeline{name: "demo",
                     producer_consumer:
                     [Data.Scrubber, Data.Analyzer],
                     opts: [statistics: :statsd]}

GenMetrics.monitor_pipeline(pipeline)

# Here Data.Scrubber and Data.Analyzer are example GenStages.
```

Note:
Explain `:statsd` integration with analysis and visualization
tools such as Grafana and Datadog.

+++

#### GenStage Statistical Metrics

#### Optional Datadog Activation

```elixir
alias GenMetrics.GenStage.Pipeline

pipeline = %Pipeline{name: "demo",
                     producer_consumer:
                     [Data.Scrubber, Data.Analyzer],
                     opts: [statistics: :datadog]}

GenMetrics.monitor_pipeline(pipeline)

# Here Data.Scrubber and Data.Analyzer are example GenStages.
```

Note:
Mention `:datadog` tagging feature is automatically activated
to support filtering on individual GenStage pipelines.

+++

#### GenStage Statistical Metrics

#### Optional In-Memory Activation

```elixir
alias GenMetrics.GenStage.Pipeline

pipeline = %Pipeline{name: "demo",
                     producer_consumer:
                     [Data.Scrubber, Data.Analyzer],
                     opts: [statistics: true]}

GenMetrics.monitor_pipeline(pipeline)

# Here Data.Scrubber and Data.Analyzer are example GenStages.
```

Note:
Again mention availability of *window_interval* option.

+++

#### GenStage Statistical Metrics

#### Sample In-Memory Metrics Data

```elixir
# Stage Name: Data.Producer, PID<0.195.0>

# callback demand
%GenMetrics.GenStage.Stats{callbacks: 9536,
                           max: 500,
                           mean: 500,
                           min: 500,
                           range: 0,
                           stdev: 0,
                           total: 4768000}

# Statistical timings measured in microseconds (µs).
```

Note:
Note GenStage summary metrics split across *demand*, *events*
and *timings* as we will see on the following slides.

+++

#### GenStage Statistical Metrics

#### Sample In-Memory Metrics Data

```elixir
# callback events
%GenMetrics.GenStage.Stats{callbacks: 9536,
                           max: 500,
                           mean: 500,
                           min: 500,
                           range: 0,
                           stdev: 0,
                           total: 4768000}

# Statistical timings measured in microseconds (µs).
```

+++

#### GenStage Statistical Metrics

#### Sample In-Memory Metrics Data

```elixir
# callback timings
%GenMetrics.GenStage.Stats{callbacks: 9536,
                           max: 2979,
                           mean: 42,
                           min: 24,
                           range: 2955,
                           stdev: 38,
                           total: 403170}

# Statistical timings measured in microseconds (µs).
```

---

### GenMetrics Reporting

- Metrics are published periodically
- By a dedicated reporting process
- Or by a statsd agent
- Any application can subscribe for metrics events
- Then aggregate, render, persist, etc metrics data

Note:
Emphasize separation of metrics collection, reporting, and consumption.

---

### GenServer Metrics Reporting

+++

#### GenMetrics.GenServer.Reporter

<span style="color:gray">A GenStage Broadcasting Producer</span>

<span style="color:gray">For In-Memory Metrics Data</span>

Note:
Clarify that the producer name is registered by GenMetrics.

+++

#### Subscribing For GenMetrics Events

```elixir
def init(:ok) do

  {:consumer, :state_does_not_matter,
   subscribe_to:
   [{GenMetrics.GenServer.Reporter, max_demand: 1}]}

end
```

Note:
Mention the reporting process is a *BroadcastDispatcher*
producer so there is opportunity for filtering using *selector*.

+++

#### Handling GenMetrics Events

```elixir
def handle_events([metrics | _], _from, state) do

  for summary <- metrics.summary do
    Logger.info "GenMetrics.Consumer: #{inspect summary}"
  end

  {:noreply, [], state}

end
```

Note:
Explain metrics can be analyzed or processed in any number
of ways including logging, persistence, Statsd, Graphana,
DataDog, etc.

---

### GenStage Metrics Reporting

+++

#### GenMetrics.GenStage.Reporter

<span style="color:gray">A GenStage Broadcasting Producer</span>

<span style="color:gray">For In-Memory Metrics Data</span>

+++

#### Subscribing For GenMetrics Events

```elixir
def init(:ok) do

  {:consumer, :state_does_not_matter,
   subscribe_to:
   [{GenMetrics.GenStage.Reporter, max_demand: 1}]}

end
```

Note:
Again clarify that the producer name is registered by GenMetrics.

+++

#### Handling GenMetrics Events

```elixir
def handle_events([metrics | _], _from, state) do

  for summary <- metrics.summary do
    Logger.info "GenMetrics.Consumer: #{inspect summary}"
  end

  {:noreply, [], state}

end
```

---

### GenMetrics is open source

- <a target="_blank" href="https://hexdocs.pm/gen_metrics/GenMetrics.html">The Hex Docs</a>
- <a target="_blank" href="https://github.com/onetapbeyond/gen_metrics">The GitHub Repo</a>
- Welcome feedback, PRs, issues, etc.

Note:
Encourage the audience to get involved, test, report, contribute.

