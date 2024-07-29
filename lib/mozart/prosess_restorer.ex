defmodule Mozart.ProcessRestorer do
  alias Mozart.ProcessService, as: PS
  alias Mozart.ProcessEngine, as: PE

  defp restore_process(pe_state) do
    {:ok, pid, _uid, _business_key} = PE.restart_process(pe_state)
    PE.restore_previous_state(pid, pe_state)
  end

  def restore_process_state() do
    persisted_processes = PS.get_persisted_processes()
    Enum.each(persisted_processes, fn {_uid, pe_state} ->  restore_process(pe_state) end)
  end
end
