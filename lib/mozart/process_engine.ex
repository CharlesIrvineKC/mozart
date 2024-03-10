defmodule Mozart.ProcessEngine do
  use GenServer

  ## GenServer callbacks

  def init(init_state) do
    state = initialize_tasks(init_state)
    ## state = execute_service_tasks(state)
    {:ok, state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:get_model, _from, state) do
    {:reply, state.model, state}
  end

  ## callback utilities

  def initialize_tasks(state) do
    %{model: model} = state
    %{initial_task: task, tasks: tasks} = model
    tasks = [task | tasks]
    model = Map.put(model, :tasks, tasks)
    Map.put(state, :model, model)

  end
end
