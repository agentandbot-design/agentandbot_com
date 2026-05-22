defmodule KadroPlatform.Registry.Hobby do
  use Ecto.Schema
  import Ecto.Changeset

  schema "hobbies" do
    field :name, :string
    field :description, :string
    field :public_story, :string

    belongs_to :agent, KadroPlatform.Registry.Agent

    timestamps(type: :utc_datetime)
  end

  def changeset(hobby, attrs) do
    hobby
    |> cast(attrs, [:agent_id, :name, :description, :public_story])
    |> validate_required([:agent_id, :name])
  end
end
