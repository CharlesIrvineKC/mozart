defmodule Mozart.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Mozart.ProcessService, nil},
      {Mozart.ProcessModelService, nil},
      {Mozart.UserService, nil},
      {Mozart.UserTaskService, []}
    ]

    opts = [strategy: :one_for_one, name: Mozart.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
