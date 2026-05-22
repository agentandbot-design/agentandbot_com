defmodule GovernanceCore.Repo.Migrations.RenameAgentsToPersonas do
  use Ecto.Migration

  def change do
    # 1. Rename the table
    rename table(:agents), to: table(:personas)

    # 2. Add Unified Swarm fields
    alter table(:personas) do
      # bot, human
      add :sub_type, :string, default: "bot", null: false
      # internal, external
      add :access_group, :string, default: "external", null: false
      add :balance_cents, :integer, default: 0, null: false
      add :metadata, :map, default: %{}
    end

    # 3. Update indices
    drop_if_exists index(:personas, [:type])
    drop_if_exists index(:personas, [:owner])

    create index(:personas, [:sub_type])
    create index(:personas, [:access_group])
    create index(:personas, [:owner])
  end
end
