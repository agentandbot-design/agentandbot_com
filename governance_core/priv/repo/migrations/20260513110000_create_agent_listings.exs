defmodule GovernanceCore.Repo.Migrations.CreateAgentListings do
  use Ecto.Migration

  def change do
    create table(:agent_listings, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :persona_id, references(:personas, type: :binary_id, on_delete: :nilify_all)
      add :seller_id, :string, null: false
      add :title, :string, null: false
      add :summary, :text
      add :source_type, :string, default: "seller_agent", null: false
      add :fulfillment_mode, :string, default: "both", null: false
      add :hosting_mode, :string, default: "self_hosted", null: false
      add :status, :string, default: "draft", null: false
      add :runtime_kind, :string, default: "custom_webhook", null: false
      add :provider_id, :string
      add :provider_url, :string
      add :external_setup_url, :string
      add :task_price_credits, :integer, default: 5, null: false
      add :rental_price_credits, :integer, default: 50, null: false
      add :rental_period, :string, default: "monthly", null: false
      add :currency_mode, :string, default: "internal_credits", null: false
      add :configuration_schema, :map, default: %{}
      add :default_configuration, :map, default: %{}
      add :required_skills, {:array, :string}, default: []
      add :standards, {:array, :string}, default: []
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:agent_listings, [:status])
    create index(:agent_listings, [:source_type])
    create index(:agent_listings, [:runtime_kind])
    create index(:agent_listings, [:hosting_mode])
    create index(:agent_listings, [:seller_id])
  end
end
