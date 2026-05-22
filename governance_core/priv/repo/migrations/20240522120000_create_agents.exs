defmodule GovernanceCore.Repo.Migrations.CreateAgents do
  use Ecto.Migration

  def change do
    create table(:agents, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :trust_score, :integer, default: 100, null: false
      add :status, :string, default: "active", null: false

      timestamps()
    end

    unless repo().__adapter__() == Ecto.Adapters.SQLite3 do
      create constraint(:agents, :trust_score_range,
               check: "trust_score >= 0 AND trust_score <= 100"
             )
    end
  end
end
