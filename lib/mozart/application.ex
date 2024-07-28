defmodule Mozart.Application do
  @moduledoc false
  use Application

  alias Mozart.ProcessRestorer

  @impl true
  def start(_type, _args) do
    children = [
      {DynamicSupervisor, name: ProcessEngineSupervisor, strategy: :one_for_one},
      {Mozart.ProcessService, nil},
      {Mozart.UserService, nil},
      {Phoenix.PubSub, name: :pubsub}
    ]

    opts = [strategy: :one_for_one, name: Mozart.Supervisor]
    result = Supervisor.start_link(children, opts)

    ProcessRestorer.restore_process_state()

    IO.inspect result, label:  "***************** APPLICATION STARTED **********************"
  end
end
