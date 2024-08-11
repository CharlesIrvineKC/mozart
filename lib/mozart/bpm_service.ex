defmodule Mozart.BpmService do
  alias Mozart.Data.BpmApplication
  alias Ecto.Adapters.SQL
  alias Mozart.Repo

  def create_bpm_app(name, main, data) do
    query = """
     insert into bpm_app (name, main, data)
     values ($1, $2, $3)
    """

    IO.inspect(SQL.query(Repo, query, [name, main, data]), label: "** insert **")
  end

  def get_bpm_apps() do
    query = """
     select name, main, data from bpm_app
    """

    {:ok, %{rows: rows}} = SQL.query(Repo, query, [])
    apps = Enum.map(rows, fn [n, m, d] -> %BpmApplication{name: n, main: m, data: d} end)
    apps
  end

  def create_process_state(data) do
    query = """
     insert into process_state (data)
     values($1)
    """

    IO.inspect(SQL.query(Repo, query, [data]), label: "** insert **")
  end

  def get_bpm_states() do
    query = """
     select * from process_state
    """

    # {:ok, %{rows: rows}} = SQL.query(Repo, query, [])
    result = SQL.query(Repo, query, [])
    result
  end
end
