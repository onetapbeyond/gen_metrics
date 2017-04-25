defmodule GenMetrics.GenStage.Pipeline do

  @moduledoc """
  A struct used to identify one or more GenStages that become candidates
  for metrics collection.

  The fields are:

  * `name` - a `String.t` used to identify the pipeline

  * `producer` - a list of one or more GenStage `:producer` modules

  * `producer_consumer` - a list of one or more GenStage
  `:producer_consumer` modules

  * `consumer` - a list of one or more GenStage `:consumer` modules

  * `opts` - a keyword list of options that alter GenMetrics behaviour
  for the pipeline

  The `name` can be used to filter metrics events from the GenMetrics
  reporting process as well as provding context when logging metrics data.

  The following `opts` are supported:

  * `statistics` - when `true`, statistical metrics are generated,
  defaults to `false`
  * `window_interval` - metrics collection interval in `ms`, defaults to `1000 ms`

  ### Usage

  Assuming your GenStage application has a `Data.Producer`, a `Data.Scrubber`,
  a `Data.Analyzer` and a `Data.Consumer` you can activate metrics collection
  for the entire pipeline as follows:

  ```
  alias GenMetrics.GenStage.Pipeline
  pipeline = %Pipeline{name: "demo",
                       producer: [Data.Producer],
                       producer_consumer: [Data.Scrubber, Data.Analyzer],
                       consumer: [Data.Consumer]}
  GenMetrics.monitor_pipeline(pipeline)
  ```

  Alternatively, if you only wanted to activate metrics collection for the
  `:producer_consumer` stages within the pipeline you can do the following:

  ```
  alias GenMetrics.GenStage.Pipeline
  pipeline = %Pipeline{name: "demo", 
                       producer_consumer: [Data.Scrubber, Data.Analyzer]}
  GenMetrics.monitor_pipeline(pipeline)
  ```

  The *pipeline* in this context is simply a named set of one or more GenStage
  modules about which you would like to collect metrics data. Metrics data are
  collected on stage processes executing on the local node.
  """

  defstruct name: nil, producer: [],
    producer_consumer: [], consumer: [], opts: []
end
