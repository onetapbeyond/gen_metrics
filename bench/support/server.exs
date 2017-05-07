defmodule TracedServer do
  use GenServer

  def start_link(target) do
    GenServer.start_link(__MODULE__, target, name: __MODULE__)
  end
  def init(target) do
    # IO.puts "init: target=#{inspect target}"
    {:ok, {target, 1}}
  end

  def init_state(target) do
    GenServer.call(__MODULE__, {:init_state, target})
  end

  def do_call(item) do
    GenServer.call(__MODULE__, {:do_call, item})
  end

  def do_cast(item) do
    GenServer.cast(__MODULE__, {:do_cast, item})
  end

  def do_info(item) do
    send(__MODULE__, {:do_info, item})
  end

  def handle_call({:init_state, target}, _from, _) do
    {:reply, :ok, {target, 1}}
  end

  def handle_call({:do_call, %{id: id}}, _from, {target, count}) do
    if count >= target, do: send(id, :benchmark_completed)
    {:reply, {:ok, id}, {target, count + 1}}
  end

  def handle_cast({:do_cast, %{id: id}}, {target, count}) do
    if count >= target, do: send(id, :benchmark_completed)
    {:noreply, {target, count + 1}}
  end

  def handle_info({:do_info, %{id: id}}, {target, count}) do
    if count >= target, do: send(id, :benchmark_completed)
    {:noreply, {target, count + 1}}
  end

end

defmodule UntracedServer do
  use GenServer

  def start_link(target) do
    GenServer.start_link(__MODULE__, target, name: __MODULE__)
  end
  def init(target) do
    # IO.puts "init: target=#{inspect target}"
    {:ok, {target, 1}}
  end

  def init_state(target) do
    GenServer.call(__MODULE__, {:init_state, target})
  end
  def do_call(item) do
    GenServer.call(__MODULE__, {:do_call, item})
  end

  def do_cast(item) do
    GenServer.cast(__MODULE__, {:do_cast, item})
  end

  def do_info(item) do
    send(__MODULE__, {:do_info, item})
  end

  def handle_call({:init_state, target}, _from, _) do
    {:reply, :ok, {target, 1}}
  end
  def handle_call({:do_call, %{id: id}}, _from, {target, count}) do
    if count >= target, do: send(id, :benchmark_completed)
    {:reply, {:ok, id}, {target, count + 1}}
  end

  def handle_cast({:do_cast, %{id: id}}, {target, count}) do
    if count + 1 >= target, do: send(id, :benchmark_completed)
    {:noreply, {target, count + 1}}
  end

  def handle_info({:do_info, %{id: id}}, {target, count}) do
    if count >= target, do: send(id, :benchmark_completed)
    {:noreply, {target, count + 1}}
  end

end
