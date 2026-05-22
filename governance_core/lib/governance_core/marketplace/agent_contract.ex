defmodule GovernanceCore.Marketplace.AgentContract do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @statuses ~w(active paused cancelled completed)

  schema "agent_contracts" do
    belongs_to :persona, GovernanceCore.Personas.Persona

    field :created_by, :string
    field :selected_runtime, :string
    field :status, :string, default: "active"
    field :metadata, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  def changeset(contract, attrs) do
    contract
    |> cast(attrs, [:persona_id, :created_by, :selected_runtime, :status, :metadata])
    |> validate_required([:persona_id, :created_by, :selected_runtime, :status])
    |> validate_inclusion(:status, @statuses)
  end
end
