defmodule Mozart.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      {Mozart.ProcessManager, nil}
    ]

    opts = [strategy: :one_for_one, name: Mozart.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
