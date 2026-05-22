defmodule GovernanceCore.Repo.Migrations.AddRuntimeAndHostingToPersonas do
  use Ecto.Migration

  def change do
    alter table(:personas) do
      add :runtime_kind, :string, default: "custom", null: false
      add :runtime_provider, :string, default: "external", null: false
      add :hosting_mode, :string, default: "affiliate", null: false
      add :hosting_url, :string
      add :agent_card_url, :string
      add :interop_standards, {:array, :string}, default: []
    end

    create index(:personas, [:runtime_kind])
    create index(:personas, [:hosting_mode])
  end
end
