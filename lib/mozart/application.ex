defmodule Mozart.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Mozart.ProcessManager, nil},
      {Mozart.UserManager, nil},
      {Mozart.TaskManager, []}
    ]

    opts = [strategy: :one_for_one, name: Mozart.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
