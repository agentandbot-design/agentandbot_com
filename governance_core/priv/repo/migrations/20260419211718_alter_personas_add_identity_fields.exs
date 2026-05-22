defmodule GovernanceCore.Repo.Migrations.AlterPersonasAddIdentityFields do
  use Ecto.Migration

  def change do
    alter table(:personas) do
      add :role, :string
      add :uptime, :string, default: "100%"
      add :tasks_done, :integer, default: 0
      add :last_seen, :naive_datetime
      add :logs, {:array, :string}, default: []
    end
  end
end
