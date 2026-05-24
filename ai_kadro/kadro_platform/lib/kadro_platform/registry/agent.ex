defmodule KadroPlatform.Registry.Agent do
  use Ecto.Schema
  import Ecto.Changeset

  @statuses ~w(draft verified published retired)
  @categories ~w(Core Global Local Archetype)

  schema "agents" do
    field :uuid, :string
    field :public_id, :string
    field :p_no, :string
    field :name, :string
    field :title, :string
    field :profession, :string
    field :category, :string
    field :country, :string
    field :city, :string
    field :age, :integer
    field :gender, :string
    field :email, :string
    field :summary, :string
    field :personality, :string
    field :content_focus, :string
    field :visual_prompt, :string
    field :portrait_path, :string
    field :full_body_path, :string
    field :instagram_mockup_path, :string
    field :cv_path, :string
    field :status, :string, default: "draft"
    field :ai_disclosure_required, :boolean, default: true
    field :identity, :map, default: %{}
    field :capabilities, {:array, :string}, default: []
    field :tool_permissions, {:array, :string}, default: []
    field :oauth_scopes, {:array, :string}, default: []
    field :agent_card, :map, default: %{}

    has_many :workplace_assignments, KadroPlatform.Registry.WorkplaceAssignment
    has_many :content_profiles, KadroPlatform.Registry.ContentProfile
    has_many :hobbies, KadroPlatform.Registry.Hobby

    timestamps(type: :utc_datetime)
  end

  def changeset(agent, attrs) do
    agent
    |> cast(attrs, [
      :uuid,
      :public_id,
      :p_no,
      :name,
      :title,
      :profession,
      :category,
      :country,
      :city,
      :age,
      :gender,
      :email,
      :summary,
      :personality,
      :content_focus,
      :visual_prompt,
      :portrait_path,
      :full_body_path,
      :instagram_mockup_path,
      :cv_path,
      :status,
      :ai_disclosure_required,
      :identity,
      :capabilities,
      :tool_permissions,
      :oauth_scopes,
      :agent_card
    ])
    |> validate_required([:uuid, :public_id, :p_no, :name, :category, :status])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:category, @categories)
    |> unique_constraint(:uuid)
    |> unique_constraint(:public_id)
    |> unique_constraint(:p_no)
  end
end
