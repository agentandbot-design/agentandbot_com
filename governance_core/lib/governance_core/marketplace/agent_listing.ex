defmodule GovernanceCore.Marketplace.AgentListing do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @source_types ~w(internal_persona seller_agent third_party_provider)
  @fulfillment_modes ~w(task_hire rental both)
  @hosting_modes ~w(hosted unhosted external_provider self_hosted)
  @statuses ~w(draft published paused archived)
  @rental_periods ~w(weekly monthly yearly)

  schema "agent_listings" do
    belongs_to :persona, GovernanceCore.Personas.Persona

    field :seller_id, :string
    field :title, :string
    field :summary, :string
    field :source_type, :string, default: "seller_agent"
    field :fulfillment_mode, :string, default: "both"
    field :hosting_mode, :string, default: "self_hosted"
    field :status, :string, default: "draft"
    field :runtime_kind, :string, default: "custom_webhook"
    field :provider_id, :string
    field :provider_url, :string
    field :external_setup_url, :string
    field :task_price_credits, :integer, default: 5
    field :rental_price_credits, :integer, default: 50
    field :rental_period, :string, default: "monthly"
    field :currency_mode, :string, default: "internal_credits"
    field :configuration_schema, :map, default: %{}
    field :default_configuration, :map, default: %{}
    field :required_skills, {:array, :string}, default: []
    field :standards, {:array, :string}, default: []
    field :metadata, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  def changeset(listing, attrs) do
    listing
    |> cast(attrs, [
      :persona_id,
      :seller_id,
      :title,
      :summary,
      :source_type,
      :fulfillment_mode,
      :hosting_mode,
      :status,
      :runtime_kind,
      :provider_id,
      :provider_url,
      :external_setup_url,
      :task_price_credits,
      :rental_price_credits,
      :rental_period,
      :currency_mode,
      :configuration_schema,
      :default_configuration,
      :required_skills,
      :standards,
      :metadata
    ])
    |> validate_required([
      :seller_id,
      :title,
      :source_type,
      :fulfillment_mode,
      :hosting_mode,
      :status,
      :runtime_kind
    ])
    |> validate_inclusion(:source_type, @source_types)
    |> validate_inclusion(:fulfillment_mode, @fulfillment_modes)
    |> validate_inclusion(:hosting_mode, @hosting_modes)
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:rental_period, @rental_periods)
    |> validate_number(:task_price_credits, greater_than_or_equal_to: 0)
    |> validate_number(:rental_price_credits, greater_than_or_equal_to: 0)
  end
end
