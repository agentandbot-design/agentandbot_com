defmodule GovernanceCore.Marketplace.AgentCapabilityPolicy do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  schema "agent_capability_policies" do
    belongs_to :persona, GovernanceCore.Personas.Persona

    field :allowed_scopes, {:array, :string}, default: []
    field :allowed_skills, {:array, :string}, default: []
    field :max_budget_credits, :integer
    field :external_endpoint, :string
    field :metadata, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  def changeset(policy, attrs) do
    policy
    |> cast(attrs, [
      :persona_id,
      :allowed_scopes,
      :allowed_skills,
      :max_budget_credits,
      :external_endpoint,
      :metadata
    ])
    |> validate_required([:persona_id])
    |> validate_number(:max_budget_credits, greater_than_or_equal_to: 0)
  end
end
