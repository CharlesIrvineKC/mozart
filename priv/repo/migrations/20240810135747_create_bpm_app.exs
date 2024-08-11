defmodule Mozart.Repo.Migrations.CreateBpmApp do
  use Ecto.Migration

  def change do
    create table("bpm_app", primary_key: true) do
      add :name, :string, primary_key: true
      add :main_process, :string
      add :data, {:array, :string}
    end
  end
end
