defmodule GenMetrics.GenServer.Cluster do

  @moduledoc """
  A struct used to identify one or more GenServer modules that become
  candidates for metrics collection.

  The fields are:

  * `name` - a `String.t` used to identify the cluster

  * `servers` - a list of one or more GenServer modules

  * `opts` - a keyword list of options that alter GenMetrics behaviour
  for the cluster

  The `name` can be used to filter metrics events from the GenMetrics
  reporting process as well as provding context when logging metrics data.

  The following `opts` are supported:

  * `statistics` - when `true`, statistical metrics are generated for
  the cluster, defaults to `false`
  * `window_interval` - metrics collection interval in `ms`, defaults to `1000 ms`

  ### Usage:

  Assuming your application has a `Session.Server` and a `Logging.Server`,
  you can activate metrics collection on both GenServers as follows:

  ```
  alias GenMetrics.GenServer.Cluster
  cluster = %Cluster{name: "demo", servers: [Session.Server, Logging.Server]}
  GenMetrics.monitor_cluster(cluster)
  ```

  The *cluster* in this context is simply a named set of one or more GenServer
  modules about which you would like to collect metrics data. Metrics data
  are collected on server processes executing on the local node.
  """

  defstruct name: nil, servers: [], opts: []

end
