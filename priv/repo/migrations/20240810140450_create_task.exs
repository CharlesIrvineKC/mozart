defmodule Mozart.Repo.Migrations.CreateTask do
  use Ecto.Migration

  def change do
    create table("task", primary_key: false) do
      add :uid, :string, primary_key: true
      add :next, :string
      add :name, :string
      add :start_time, :string
      add :finish_time, :string
      add :duration, :string
      add :type, :string
      add :process_uid, :string
      add :status, :string
      add :condition, :string
      add :exception_first, :string
      add :cases, {:array, :string}
      add :inputs, {:array, :string}
      add :multi_next, {:array, :string}
      add :data, {:map, :string}
      add :selector, :string
      add :module, :string
      add :complete, :boolean
      add :rule_table, :string
      add :message, :str
    end
  end
end
