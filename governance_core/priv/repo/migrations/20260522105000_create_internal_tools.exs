defmodule GovernanceCore.Repo.Migrations.CreateInternalTools do
  use Ecto.Migration

  def change do
    create_if_not_exists table(:internal_tools, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :slug, :string, null: false
      add :name, :string, null: false
      add :url, :string
      add :internal_url, :string
      add :container_name, :string
      add :category, :string, null: false
      add :owner, :string
      add :audience, {:array, :string}, default: []
      add :agent_access, :string, default: "false"
      add :status, :string, default: "unknown"
      add :auth_mode, :string
      add :health, :string, default: "unknown"
      add :data_classification, :string, default: "internal"
      add :allowed_agent_scopes, {:array, :string}, default: []
      add :secrets_ref, :string
      add :notes, :text
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create_if_not_exists unique_index(:internal_tools, [:slug])
    create_if_not_exists index(:internal_tools, [:category])
    create_if_not_exists index(:internal_tools, [:status])
    create_if_not_exists index(:internal_tools, [:agent_access])
  end
end
