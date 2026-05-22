defmodule GovernanceCore.Repo.Migrations.AddCareerAndDeploymentToPersonas do
  use Ecto.Migration

  def change do
    alter table(:personas) do
      add :level, :integer, default: 1, null: false
      add :xp, :integer, default: 0, null: false
      add :achievements, {:array, :string}, default: [], null: false
      add :memory_keys_count, :integer, default: 0, null: false
      add :deployed_endpoint, :string
    end
  end
end
