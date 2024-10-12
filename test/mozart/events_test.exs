defmodule Mozart.EventsTest do
  # use ExUnit.Case
  # use Mozart.BpmProcess

  # alias Mozart.ProcessEngine, as: PE
  # alias Mozart.ProcessService, as: PS

  # def schedule_timer_expiration(task_uid, process_uid, timer_duration) do
  #   spawn(fn -> wait_and_notify(task_uid, process_uid, timer_duration) end)
  # end

  # defprocess "Pizza Order" do
  #   subprocess_task("Prepare and Deliver Subprocess Task", process: "Prepare and Deliver Pizza")
  # end

  # defprocess "Prepare and Deliver Pizza" do
  #   timer_task("Prepare Pizza", duration: 2000, function: :schedule_timer_expiration)
  #   timer_task("Deliver Pizza", duration: 2000, function: :schedule_timer_expiration)
  # end

  # def_task_exit_event "Cancel Pizza Order",
  #   process: "Pizza Order",
  #   exit_task: "Prepare and Deliver Subprocess Task",
  #   selector: :exit_subprocess_task_event_selector do
  #   prototype_task("Cancel Preparation")
  #   prototype_task("Cancel Delivery")
  # end

  # def exit_subprocess_task_event_selector(event) do
  #   event == :exit_subprocess_task
  # end

  # def send_timer_expired(task_uid, process_uid) do
  #   ppid = PS.get_process_pid_from_uid(process_uid)
  #   if ppid, do: send(ppid, {:timer_expired, task_uid})
  # end

  # defp wait_and_notify(task_uid, process_uid, timer_duration) do
  #   :timer.apply_after(timer_duration, __MODULE__, :send_timer_expired, [task_uid, process_uid])
  # end

  # test "Pizza Order" do
  #   PS.clear_state()
  #   load()

  #   {:ok, ppid1, _uid1, _business_key1} = PE.start_process("Pizza Order", %{})

  #   PE.execute(ppid1)

  #   Process.sleep(500)

  #   send(ppid1, {:exit_task_event, :exit_subprocess_task})
  # end
end
