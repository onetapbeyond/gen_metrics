# Usage: mix run examples/genserver_events.exs
#
# This basic example demonstrates the collection and
# reporting of metrics data for a simple GenServer cluster.
# 
# The sample Metrics.Consumer module simply prints the metrics
# data reported by the GenMetrics library to standard out.
#
defmodule Demo.Server do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [])
  end

  def init(state) do
    {:ok, state}
  end

  def handle_call(_msg, _from, state) do
    {:reply, :ok, state}
  end

  def handle_cast(_msg, state) do
    {:noreply, state}
  end

  def handle_info(_msg, state) do
    {:noreply, state}
  end
end

defmodule Metrics.Consumer do
  use GenStage

  def start_link do
    GenStage.start_link(__MODULE__, [])
  end

  def init(_state) do
    {:consumer, :state_does_not_matter,
     subscribe_to: [{GenMetrics.GenServer.Reporter, max_demand: 1}]}
  end

  def handle_events([window | _], _from, state) do
    IO.puts "\n\nGenServer Cluster: #{inspect window.cluster.name}"
    IO.puts "Metrics-Window: Start:=#{inspect window.start}, Duration=#{inspect window.duration}"
    IO.puts "Summary Metrics"
    for summary <- window.summary do
      IO.puts "#{inspect summary}"
    end
    IO.puts "Statistical Metrics"
    for server <- window.stats do
      IO.puts "Server:=#{inspect server.name} [ #{inspect server.pid} ]"
      IO.puts "Calls:=#{inspect server.calls}"
      IO.puts "Casts:=#{inspect server.casts}"
      IO.puts "Infos:=#{inspect server.infos}"
    end
    IO.puts "\n"
    {:noreply, [], state}
  end
end


#
# Initialize GenMetrics Monitoring for GenServer Cluster
#
alias GenMetrics.GenServer.Cluster

Application.start(GenMetrics.Application)
Metrics.Consumer.start_link

cluster = %Cluster{name: "demo",
                   servers: [Demo.Server],
                   opts: [statistics: true,
                          sample_rate: 0.95,
                          window_interval: 2000,
                          synchronous: true]}

{:ok, _pid} = GenMetrics.monitor_cluster(cluster)

#
# Start Sample GenServer To Handle Events
#
{:ok, pid} = GenServer.start_link(Demo.Server, [])
spawn fn ->
  for _ <- 1..3500 do
    GenServer.call(pid, :demo)
    GenServer.cast(pid, :demo)
    Kernel.send(pid, :demo)
  end
end
GenServer.call(pid, :demo)
Process.sleep(5000)
