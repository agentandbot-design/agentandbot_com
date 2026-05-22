defmodule GovernanceCore.Marketplace.TaskEvent do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @event_types ~w(queued accepted working artifact_submitted completed failed delegated rejected expired cancelled refunded message commerce_intent)

  schema "task_events" do
    belongs_to :task, GovernanceCore.Marketplace.Task

    field :actor, :string
    field :event_type, :string
    field :message, :string
    field :artifact_url, :string
    field :metadata, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  def changeset(event, attrs) do
    event
    |> cast(attrs, [:task_id, :actor, :event_type, :message, :artifact_url, :metadata])
    |> validate_required([:task_id, :actor, :event_type])
    |> validate_inclusion(:event_type, @event_types)
  end
end
