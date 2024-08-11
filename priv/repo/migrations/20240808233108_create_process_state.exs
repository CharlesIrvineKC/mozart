defmodule Mozart.Repo.Migrations.CreateProcessState do
  use Ecto.Migration

  def change do
    create table(:process_state, primary_key: false) do
      add :uid, :string, primary_key: true
      add :business_key, :string
      add :parent_uid, :string
      add :model_name, :string
      add :start_time, :string
      add :end_time, :string
      add :execute_duration, :string
      add :complete, :boolean
      add :data, {:map, :string}
    end
  end
end
