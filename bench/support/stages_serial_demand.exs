defmodule TracedSerialProducer do
  use GenStage

  def start_link do
    GenStage.start_link(__MODULE__, [], name: __MODULE__)
  end
  def init(_) do
    {:producer, {:queue.new, 0}}
  end

  def emit(item) do
    GenStage.call(__MODULE__, {:emit, item})
  end

  def handle_call({:emit, item}, {pid, _ref} = from, {queue, demand}) do
    event = Map.put(item, :pid, pid)
    dispatch_events(:queue.in({from, event}, queue), demand, [])
  end
  def handle_demand(incoming_demand, {queue, demand}) do
    dispatch_events(queue, incoming_demand + demand, [])
  end

  defp dispatch_events(queue, demand, events) do
    with d when d > 0 <- demand,
         {{:value, {from, event}}, queue} <- :queue.out(queue) do
      GenStage.reply(from, {:ok, event.id})
      dispatch_events(queue, demand - 1, [event | events])
    else
      _ -> {:noreply, Enum.reverse(events), {queue, demand}}
    end
  end
end

defmodule TracedSerialConsumer do
  use GenStage

  def start_link do
    GenStage.start_link(__MODULE__, [], name: __MODULE__)
  end
  def init(_) do
    {:consumer, nil, subscribe_to: [{TracedSerialProducer, max_demand: 1}]}
  end

  def handle_events([%{id: id, pid: pid} | _], _from, state) do
    send(pid, id)
    {:noreply, [], state}
  end
end

defmodule UntracedSerialProducer do
  use GenStage

  def start_link do
    GenStage.start_link(__MODULE__, [], name: __MODULE__)
  end
  def init(_) do
    {:producer, {:queue.new, 0}}
  end

  def emit(item) do
    GenStage.call(__MODULE__, {:emit, item})
  end

  def handle_call({:emit, item}, {pid, _ref} = from, {queue, demand}) do
    event = Map.put(item, :pid, pid)
    dispatch_events(:queue.in({from, event}, queue), demand, [])
  end
  def handle_demand(incoming_demand, {queue, demand}) do
    dispatch_events(queue, incoming_demand + demand, [])
  end

  defp dispatch_events(queue, demand, events) do
    with d when d > 0 <- demand,
         {{:value, {from, event}}, queue} <- :queue.out(queue) do
      GenStage.reply(from, {:ok, event.id})
      dispatch_events(queue, demand - 1, [event | events])
    else
      _ -> {:noreply, Enum.reverse(events), {queue, demand}}
    end
  end
end

defmodule UntracedSerialConsumer do
  use GenStage

  def start_link do
    GenStage.start_link(__MODULE__, [], name: __MODULE__)
  end
  def init(_) do
    {:consumer, nil, subscribe_to: [{UntracedSerialProducer, max_demand: 1}]}
  end

  def handle_events([%{id: id, pid: pid} | _], _from, state) do
    send(pid, id)
    {:noreply, [], state}
  end
end
