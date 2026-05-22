defmodule KadroPlatform.Registry.ContentProfile do
  use Ecto.Schema
  import Ecto.Changeset

  schema "content_profiles" do
    field :platform, :string
    field :handle, :string
    field :audience, :string
    field :themes, {:array, :string}, default: []
    field :cadence, :string
    field :disclosure_label, :string, default: "AI virtual worker"
    field :status, :string, default: "planned"

    belongs_to :agent, KadroPlatform.Registry.Agent

    timestamps(type: :utc_datetime)
  end

  def changeset(profile, attrs) do
    profile
    |> cast(attrs, [
      :agent_id,
      :platform,
      :handle,
      :audience,
      :themes,
      :cadence,
      :disclosure_label,
      :status
    ])
    |> validate_required([:agent_id, :platform, :disclosure_label, :status])
  end
end
