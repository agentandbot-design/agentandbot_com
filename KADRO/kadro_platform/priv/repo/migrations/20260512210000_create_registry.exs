defmodule KadroPlatform.Repo.Migrations.CreateRegistry do
  use Ecto.Migration

  def change do
    create table(:agents) do
      add :uuid, :string, null: false
      add :public_id, :string, null: false
      add :p_no, :string, null: false
      add :name, :string, null: false
      add :title, :string
      add :profession, :string
      add :category, :string, null: false
      add :country, :string
      add :city, :string
      add :age, :integer
      add :gender, :string
      add :email, :string
      add :summary, :text
      add :personality, :text
      add :content_focus, :text
      add :visual_prompt, :text
      add :portrait_path, :string
      add :full_body_path, :string
      add :instagram_mockup_path, :string
      add :cv_path, :string
      add :status, :string, null: false, default: "draft"
      add :ai_disclosure_required, :boolean, null: false, default: true
      add :identity, :map, null: false, default: %{}
      add :capabilities, {:array, :string}, null: false, default: []
      add :tool_permissions, {:array, :string}, null: false, default: []
      add :oauth_scopes, {:array, :string}, null: false, default: []
      add :agent_card, :map, null: false, default: %{}

      timestamps(type: :utc_datetime)
    end

    create unique_index(:agents, [:uuid])
    create unique_index(:agents, [:public_id])
    create unique_index(:agents, [:p_no])
    create index(:agents, [:category])
    create index(:agents, [:status])

    create table(:workplace_assignments) do
      add :agent_id, references(:agents, on_delete: :delete_all), null: false
      add :company, :string, null: false
      add :department, :string
      add :title, :string, null: false
      add :status, :string, null: false, default: "active"
      add :started_on, :date
      add :ended_on, :date
      add :summary, :text
      add :handover_notes, :text

      timestamps(type: :utc_datetime)
    end

    create index(:workplace_assignments, [:agent_id])
    create index(:workplace_assignments, [:status])

    create table(:content_profiles) do
      add :agent_id, references(:agents, on_delete: :delete_all), null: false
      add :platform, :string, null: false
      add :handle, :string
      add :audience, :string
      add :themes, {:array, :string}, null: false, default: []
      add :cadence, :string
      add :disclosure_label, :string, null: false, default: "AI virtual worker"
      add :status, :string, null: false, default: "planned"

      timestamps(type: :utc_datetime)
    end

    create index(:content_profiles, [:agent_id])
    create index(:content_profiles, [:platform])

    create table(:hobbies) do
      add :agent_id, references(:agents, on_delete: :delete_all), null: false
      add :name, :string, null: false
      add :description, :text
      add :public_story, :text

      timestamps(type: :utc_datetime)
    end

    create index(:hobbies, [:agent_id])
  end
end
