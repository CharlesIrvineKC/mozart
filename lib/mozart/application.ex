defmodule Mozart.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {DynamicSupervisor, name: ProcessEngineSupervisor, strategy: :one_for_one},
      {Mozart.ProcessService, nil},
      {Mozart.ProcessModelService, nil},
      {Mozart.UserService, nil},
      {Phoenix.PubSub, name: :pubsub}
    ]

    opts = [strategy: :one_for_one, name: Mozart.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
