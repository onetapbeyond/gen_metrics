defmodule TracedServer do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end
  def init(_) do
    {:ok, nil}
  end

  def do_call(item) do
    GenServer.call(__MODULE__, {:do_call, item})
  end

  def handle_call({:do_call, %{id: id}}, _from, state) do
    {:reply, {:ok, id}, state}
  end
end

defmodule UntracedServer do
  use GenServer

  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end
  def init(_) do
    {:ok, nil}
  end

  def do_call(item) do
    GenServer.call(__MODULE__, {:do_call, item})
  end

  def handle_call({:do_call, %{id: id}}, _from, state) do
    {:reply, {:ok, id}, state}
  end
end
