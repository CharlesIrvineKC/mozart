defmodule Mozart.ProcessEngine do
  use GenServer

  alias Mozart.ProcessEngine
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

  def get_open_tasks(ppid) do
    GenServer.call(ppid, :get_open_tasks)
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
    state = %ProcessState{model: model, data: data, uid: uid, open_tasks: [], parent: parent}
    state = insert_new_task(state, state.model.initial_task)
    IO.puts "call execute fromn init"
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

  def insert_new_task(state, task_name) do
    IO.inspect(task_name, label: "task_name")
    new_task = get_task(task_name, state)
    if new_task.type == :user, do: UserTaskService.insert_user_task(new_task)
    task_instance = new_task_instance(new_task)
    Map.put(state, :open_tasks, [task_instance | state.open_tasks])
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

  def handle_call(:get_open_tasks, _from, state) do
    {:reply, state.open_tasks, state}
  end

  def handle_cast({:complete_user_task, task_name, return_data}, state) do
    state =
      if Enum.find(state.open_tasks, fn ot -> ot.task_name == task_name end) do
        data = Map.merge(state.data, return_data)
        state = Map.put(state, :data, data)
        open_tasks = Enum.reject(state.open_tasks, fn task -> task.task_name == task_name end)
        state = Map.put(state, :open_tasks, open_tasks)
        execute_process(state)
      else
        state
      end

    {:noreply, state}
  end

  def handle_cast({:notify_child_complete, sub_process_name, child_data}, state) do
    state = Map.put(state, :data, Map.merge(state.data, child_data))

    open_tasks =
      Enum.reject(state.open_tasks, fn task ->
        task.sub_process_impl == sub_process_name
      end)

    task = get_task_by_sub_process_name(sub_process_name, state)
    open_tasks = [new_task_instance(task) | open_tasks]
    state = Map.put(state, :open_tasks, open_tasks)
    IO.puts "call execute from notify_child_complete"
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
    open_tasks = Enum.reject(state.open_tasks, fn otask -> otask.task_name == task.name end)
    state = Map.put(state, :open_tasks, open_tasks)

    state =
      if task.next != nil do
        insert_new_task(state, task.next)
      else
        state
      end
    IO.puts "call execute from complete service task"
    execute_process(state)
  end

  def complete_choice_task(task, state) do
    next_task_name =
      Enum.find_value(
        task.choices,
        fn choice -> if choice.expression.(state.data), do: choice.next end
      )

    state = insert_new_task(state, next_task_name)
    open_tasks = Enum.reject(state.open_tasks, fn otask -> otask.task_name == task.name end)
    state = Map.put(state, :open_tasks, open_tasks)
    execute_process(state)
  end

  def call_subprocess_task(otask, state) do
    sub_process_model = ProcessModelService.get_process_model(otask.sub_process)
    data = state.data
    {:ok, process_pid} = start_link(sub_process_model, data, self())
    state = Map.put(state, :children, [process_pid | state.children])
    IO.puts "call execute from call subprocess task"
    execute_process(state)
  end

  defp get_task(task_name, state) do
    Enum.find(state.model.tasks, fn task -> task.name == task_name end)
  end

  defp get_task_by_sub_process_name(sub_process_name, state) do
    Enum.find(state.model.tasks, fn task -> sub_process_name == task.sub_process end)
  end

  def get_executable_task(state) do
    task_name =
      Enum.find_value(state.open_tasks, fn otask ->
        if is_executable(otask, state), do: otask.task_name
      end)

    if task_name, do: get_task(task_name, state)
  end

  defp is_executable(otask, state) do
    task = get_task(otask.task_name, state)

    if task.type == :service || task.type == :choice ||
         (task.type == :sub_process && !otask.pending),
       do: true,
       else: false
  end

  defp set_subprocess_task_pending(executable_task, state) do
    otask = Enum.find(state.open_tasks, fn ot -> ot.task_name == executable_task.name end)
    otask = %TaskInstance{otask | pending: true}

    open_tasks =
      Enum.map(state.open_tasks, fn ot ->
        if ot.task_name == ot.task_name, do: otask, else: ot
      end)

    Map.put(state, :open_tasks, open_tasks)
  end

  defp execute_process(state) do
    IO.inspect(self(), label: "*********** execute_process ********************")
    IO.inspect(state.model.name, label: "state.model.name")
    IO.inspect(state.open_tasks, label: "open tasks")

    if state.open_tasks != [] do
      executable_task = get_executable_task(state)

      if executable_task do
        IO.inspect(executable_task.name, label: "executable_task.name")

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
      state = Map.put(state, :complete, true)

      if state.parent do
        ProcessEngine.notify_child_complete(state.parent, state.model.name, state.data)
      else
        state
      end
    end
  end
end
