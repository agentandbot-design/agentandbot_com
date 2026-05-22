defmodule GovernanceCore.Repo.Migrations.CreateMarketplaceHireTables do
  use Ecto.Migration

  def change do
    create table(:agent_contracts, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :persona_id, references(:personas, type: :binary_id, on_delete: :delete_all),
        null: false

      add :created_by, :string, null: false
      add :selected_runtime, :string, null: false
      add :status, :string, default: "active", null: false
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create table(:agent_capability_policies, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :persona_id, references(:personas, type: :binary_id, on_delete: :delete_all),
        null: false

      add :allowed_scopes, {:array, :string}, default: []
      add :allowed_skills, {:array, :string}, default: []
      add :max_budget_credits, :integer
      add :external_endpoint, :string
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:agent_capability_policies, [:persona_id])

    create table(:tasks, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :agent_id, references(:personas, type: :binary_id, on_delete: :nilify_all), null: false
      add :created_by, :string, null: false
      add :title, :string, null: false
      add :instructions, :text
      add :required_skill, :string
      add :expected_artifact, :string
      add :deadline_at, :utc_datetime
      add :budget_credits, :integer, default: 0, null: false
      add :status, :string, default: "draft", null: false
      add :artifact_url, :string
      add :delegated_from_task_id, references(:tasks, type: :binary_id, on_delete: :nilify_all)
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:tasks, [:agent_id])
    create index(:tasks, [:created_by])
    create index(:tasks, [:status])

    create table(:task_events, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :task_id, references(:tasks, type: :binary_id, on_delete: :delete_all), null: false
      add :actor, :string, null: false
      add :event_type, :string, null: false
      add :message, :text
      add :artifact_url, :string
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:task_events, [:task_id])
    create index(:task_events, [:event_type])

    create table(:credit_ledger_entries, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, :string, null: false
      add :agent_id, references(:personas, type: :binary_id, on_delete: :nilify_all)
      add :task_id, references(:tasks, type: :binary_id, on_delete: :nilify_all)
      add :entry_type, :string, null: false
      add :amount_credits, :integer, null: false
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:credit_ledger_entries, [:account_id])
    create index(:credit_ledger_entries, [:agent_id])
    create index(:credit_ledger_entries, [:task_id])
    create index(:credit_ledger_entries, [:entry_type])
  end
end
