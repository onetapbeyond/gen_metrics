defmodule GenMetrics.GenServer.Supervisor do
  @moduledoc false
  use Supervisor
  alias GenMetrics.GenServer.Monitor

  def start_link do
    Supervisor.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init(_) do

    children = [
      worker(Monitor, [], restart: :transient)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

end
