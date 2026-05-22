defmodule GovernanceCore.Marketplace.Task do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @statuses ~w(draft escrowed accepted working artifact_submitted completed rejected expired cancelled refunded failed delegated)

  schema "tasks" do
    belongs_to :agent, GovernanceCore.Personas.Persona
    belongs_to :delegated_from_task, __MODULE__
    has_many :events, GovernanceCore.Marketplace.TaskEvent

    field :created_by, :string
    field :title, :string
    field :instructions, :string
    field :required_skill, :string
    field :expected_artifact, :string
    field :deadline_at, :utc_datetime
    field :budget_credits, :integer, default: 0
    field :status, :string, default: "draft"
    field :artifact_url, :string
    field :metadata, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  def changeset(task, attrs) do
    task
    |> cast(attrs, [
      :agent_id,
      :created_by,
      :title,
      :instructions,
      :required_skill,
      :expected_artifact,
      :deadline_at,
      :budget_credits,
      :status,
      :artifact_url,
      :delegated_from_task_id,
      :metadata
    ])
    |> validate_required([:agent_id, :created_by, :title, :budget_credits, :status])
    |> validate_inclusion(:status, @statuses)
    |> validate_number(:budget_credits, greater_than_or_equal_to: 0)
  end
end
