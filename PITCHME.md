## GenMetrics

<span style="color:gray">Elixir GenServer and GenStage Runtime Metrics</span>

---

### Runtime Metrics

- Summary Metrics
- Plus optional Statistical Metrics
- For any GenServer or GenStage Application

---

### Hex Package

```elixir
def deps do
  [{:gen_metrics, "~> 0.1.0"}]
end
```

---

### GenServer Metrics

+++

```elixir
alias GenMetrics.GenServer.Cluster
cluster = %Cluster{name: "demo",
                   servers: [Session.Server, Logging.Server]}
GenMetrics.monitor_cluster(cluster)
```

+++

### GenServer Summary Metrics

Metrics data collected on the following callbacks:

- GenServer.handle_call/3
- GenServer.handle_cast/2
- GenServer.handle_info/2

+++

### Sample: GenServer Summary Metrics

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

### GenServer Statistical Metrics

Optional activation as follows:

```elixir
alias GenMetrics.GenServer.Cluster
cluster = %Cluster{name: "demo",
                   servers: [Session.Server, Logging.Server],
                   opts: [statistics: true]}
GenMetrics.monitor_cluster(cluster)
```

+++

### Sample: GenServer Statistical Metrics

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

### Sample: GenServer Statistical Metrics

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

### Sample: GenServer Statistical Metrics

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
