defmodule Mozart.ProcessEngine do
  use GenServer

  alias Mozart.ProcessEngine
  alias Mozart.ProcessService
  alias Mozart.Data.ProcessState
  alias Mozart.Data.TaskInstance
  alias Mozart.UserTaskService
  alias Mozart.ProcessModelService
  alias Ecto.UUID

  ## Client API

  def start_link(model, data, parent \\ nil) do
    GenServer.start_link(__MODULE__, {model, data, parent})
  end

  def get_state(ppid) do
    GenServer.call(ppid, :get_state)
  end

  def get_uid(ppid) do
    GenServer.call(ppid, :get_uid)
  end

  def get_model(ppid) do
    GenServer.call(ppid, :get_model)
  end

  def get_data(ppid) do
    GenServer.call(ppid, :get_data)
  end

  def get_task_instances(ppid) do
    GenServer.call(ppid, :get_task_instances)
  end

  def complete_user_task(ppid, task_id, data) do
    GenServer.cast(ppid, {:complete_user_task, task_id, data})
  end

  def set_data(ppid, data) do
    GenServer.cast(ppid, {:set_data, data})
  end

  def is_complete(ppid) do
    GenServer.call(ppid, :is_complete)
  end

  def notify_child_complete(parent_pid, sub_process_name, data) do
    GenServer.cast(parent_pid, {:notify_child_complete, sub_process_name, data})
  end

  ## GenServer callbacks

  def init({model, data, parent}) do
    uid = UUID.generate()

    state = %ProcessState{
      model: model,
      data: data,
      uid: uid,
      task_instances: [],
      pending_sub_tasks: [],
      parent: parent
    }

    state = process_next_task(state, state.model.initial_task)
    ProcessService.register_process_instance(uid, self())
    state = execute_process(state)
    {:ok, state}
  end

  def new_task_instance(task) do
    if task.type == :sub_process do
      %TaskInstance{task_name: task.name, sub_process_impl: task.sub_process}
    else
      %TaskInstance{task_name: task.name}
    end
  end

  def process_next_task(state, task_name) do
    task_def = get_task_def(task_name, state)
    cond do
      task_def.type == :user ->
        UserTaskService.insert_user_task(task_def)
        task_instance = new_task_instance(task_def)
        Map.put(state, :task_instances, [task_instance | state.task_instances])
      Enum.member?([:service, :choice, :sub_process, :join], task_def.type) ->
        task_instance = new_task_instance(task_def)
        Map.put(state, :task_instances, [task_instance | state.task_instances])
    end
  end

  def handle_call(:is_complete, _from, state) do
    {:reply, state.complete, state}
  end

  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  def handle_call(:get_model, _from, state) do
    {:reply, state.model, state}
  end

  def handle_call(:get_uid, _from, state) do
    {:reply, state.uid, state}
  end

  def handle_call(:get_data, _from, state) do
    {:reply, state.data, state}
  end

  def handle_call(:get_task_instances, _from, state) do
    {:reply, state.task_instances, state}
  end

  def handle_cast({:complete_user_task, task_name, return_data}, state) do
    state =
      if Enum.find(state.task_instances, fn t_i -> t_i.task_name == task_name end) do
        data = Map.merge(state.data, return_data)
        state = Map.put(state, :data, data)

        task_instances =
          Enum.reject(state.task_instances, fn task -> task.task_name == task_name end)

        state = Map.put(state, :task_instances, task_instances)

        task_def = get_task_def(task_name, state)

        state =
          if task_def.next, do: process_next_task(state, task_def.next), else: state

        execute_process(state)
      else
        state
      end

    {:noreply, state}
  end

  def handle_cast({:notify_child_complete, sub_process_name, child_data}, state) do
    state = Map.put(state, :data, Map.merge(state.data, child_data))

    pending_sub_tasks =
      Enum.reject(state.pending_sub_tasks, fn task ->
        task.sub_process_impl == sub_process_name
      end)

    state = Map.merge(state, %{pending_sub_tasks: pending_sub_tasks})

    task = get_task_def_by_sub_process_name(sub_process_name, state)
    state = if task.next, do: process_next_task(state, task.next), else: state

    state = execute_process(state)
    {:noreply, state}
  end

  def handle_cast({:set_model, model}, state) do
    {:noreply, Map.put(state, :model, model)}
  end

  def handle_cast({:set_data, data}, state) do
    {:noreply, Map.put(state, :data, data)}
  end

  ## callback utilities

  defp complete_service_task(task, state) do
    data = task.function.(state.data)
    state = Map.put(state, :data, data)

    task_instances =
      Enum.reject(state.task_instances, fn task_i -> task_i.task_name == task.name end)

    state = Map.put(state, :task_instances, task_instances)

    state = if task.next, do: process_next_task(state, task.next), else: state
    execute_process(state)
  end

  def complete_choice_task(task, state) do
    next_task_name =
      Enum.find_value(
        task.choices,
        fn choice -> if choice.expression.(state.data), do: choice.next end
      )

    state = process_next_task(state, next_task_name)

    task_instances =
      Enum.reject(state.task_instances, fn task_i -> task_i.task_name == task.name end)

    state = Map.put(state, :task_instances, task_instances)
    execute_process(state)
  end

  def call_subprocess_task(task_i, state) do
    sub_process_model = ProcessModelService.get_process_model(task_i.sub_process)
    data = state.data
    {:ok, process_pid} = start_link(sub_process_model, data, self())
    state = Map.put(state, :children, [process_pid | state.children])
    execute_process(state)
  end

  defp get_task_def(task_name, state) do
    Enum.find(state.model.tasks, fn task -> task.name == task_name end)
  end

  defp get_task_def_by_sub_process_name(sub_process_name, state) do
    Enum.find(state.model.tasks, fn task -> sub_process_name == task.sub_process end)
  end

  def get_executable_task(state) do
    task_name =
      Enum.find_value(state.task_instances, fn task_i ->
        if is_executable(task_i, state), do: task_i.task_name
      end)

    if task_name, do: get_task_def(task_name, state)
  end

  defp is_executable(task_i, state) do
    task = get_task_def(task_i.task_name, state)

    if task.type == :service || task.type == :choice || task.type == :sub_process,
      do: true,
      else: false
  end

  defp set_subprocess_task_pending(executable_task, state) do
    task_i = Enum.find(state.task_instances, fn t_i -> t_i.task_name == executable_task.name end)

    task_instances =
      Enum.reject(state.task_instances, fn t_i ->
        if t_i.task_name == t_i.task_name, do: task_i, else: t_i
      end)

    pending_sub_tasks = [task_i | state.pending_sub_tasks]

    state
    |> Map.put(:task_instances, task_instances)
    |> Map.put(:pending_sub_tasks, pending_sub_tasks)
  end

  defp work_remaining(state) do
    state.task_instances != [] || state.pending_sub_tasks != []
  end

  defp execute_process(state) do
    if work_remaining(state) do
      executable_task = get_executable_task(state)

      if executable_task do
        cond do
          executable_task.type == :service ->
            complete_service_task(executable_task, state)

          executable_task.type == :choice ->
            complete_choice_task(executable_task, state)

          executable_task.type == :sub_process ->
            state = set_subprocess_task_pending(executable_task, state)
            call_subprocess_task(executable_task, state)
        end
      else
        state
      end
    else
      ## process is complete
      if state.parent do
        ProcessEngine.notify_child_complete(state.parent, state.model.name, state.data)
      end

      Map.put(state, :complete, true)
    end
  end
end
