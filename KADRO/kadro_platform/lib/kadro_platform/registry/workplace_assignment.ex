defmodule KadroPlatform.Registry.WorkplaceAssignment do
  use Ecto.Schema
  import Ecto.Changeset

  schema "workplace_assignments" do
    field :company, :string
    field :department, :string
    field :title, :string
    field :status, :string, default: "active"
    field :started_on, :date
    field :ended_on, :date
    field :summary, :string
    field :handover_notes, :string

    belongs_to :agent, KadroPlatform.Registry.Agent

    timestamps(type: :utc_datetime)
  end

  def changeset(assignment, attrs) do
    assignment
    |> cast(attrs, [
      :agent_id,
      :company,
      :department,
      :title,
      :status,
      :started_on,
      :ended_on,
      :summary,
      :handover_notes
    ])
    |> validate_required([:agent_id, :company, :title, :status])
  end
end
