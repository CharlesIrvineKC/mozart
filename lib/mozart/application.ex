defmodule Mozart.Application do
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {DynamicSupervisor, name: ProcessEngineSupervisor, strategy: :one_for_one},
      {Mozart.ProcessService, nil},
      {Mozart.ProcessModelService, nil},
      {Mozart.UserService, nil},
      {Phoenix.PubSub, name: Mozart.SubPub}
    ]

    opts = [strategy: :one_for_one, name: Mozart.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
