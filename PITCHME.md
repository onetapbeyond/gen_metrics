## GenMetrics

<span style="color:gray">Elixir GenServer and GenStage Runtime Metrics</span>

---

### Runtime Metrics

- Summary Metrics
- Plus optional Statistical Metrics
- For any GenServer or GenStage Application
- *Without* requiring code instrumentation

---

### Hex Package Dependency

```elixir
def deps do
  [{:gen_metrics, "~> 0.1.0"}]
end
```

---

### GenServer Metrics

+++

#### GenServer Metrics Per Server

- Number of `call`, `cast`, and `info` callbacks
- Time taken on these callbacks
- Plus optional detailed statistical metrics

+++

#### GenMetrics Activation

```elixir
alias GenMetrics.GenServer.Cluster
cluster = %Cluster{name: "demo",
                   servers: [Session.Server, Logging.Server]}
GenMetrics.monitor_cluster(cluster)
```

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
```

+++

#### GenServer Statistical Metrics

#### Optional activation as follows:

```elixir
alias GenMetrics.GenServer.Cluster
cluster = %Cluster{name: "demo",
                   servers: [Session.Server, Logging.Server],
                   opts: [statistics: true]}
GenMetrics.monitor_cluster(cluster)
```

+++

#### GenServer Statistical Metrics

#### Sample Metrics Data

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
```

+++

#### GenServer Statistical Metrics

#### Sample Metrics Data

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
```

+++

#### GenServer Statistical Metrics

#### Sample Metrics Data

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
```

---

### GenStage Metrics

+++

#### GenStage Metrics Per Stage

- Number of `demand` and `events` callbacks
- Time taken on these callbacks
- Size of upstream demand
- Size of events emitted
- Plus optional detailed statistical metrics

+++

#### GenStage Activation

```elixir
alias GenMetrics.GenStage.Pipeline
pipeline = %Pipeline{name: "demo",
                     producer_consumer:
                     [Data.Scrubber, Data.Analyzer],
                     opts: [window_interval: 5000]}
GenMetrics.monitor_pipeline(pipeline)
```

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
```

+++

#### GenStage Statistical Metrics

#### Optional activation as follows:

```elixir
alias GenMetrics.GenStage.Pipeline
pipeline = %Pipeline{name: "demo",
                     producer_consumer:
                     [Data.Scrubber, Data.Analyzer],
                     opts: [statistics: true]}
GenMetrics.monitor_pipeline(pipeline)
```

+++

#### GenStage Statistical Metrics

#### Sample Metrics Data

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
```

+++

#### GenStage Statistical Metrics

#### Sample Metrics Data

```elixir
# callback events
%GenMetrics.GenStage.Stats{callbacks: 9536,
                           max: 500,
                           mean: 500,
                           min: 500,
                           range: 0,
                           stdev: 0,
                           total: 4768000}
```

+++

#### GenStage Statistical Metrics

#### Sample Metrics Data

```elixir
# callback timings
%GenMetrics.GenStage.Stats{callbacks: 9536,
                           max: 2979,
                           mean: 42,
                           min: 24,
                           range: 2955,
                           stdev: 38,
                           total: 403170}
```