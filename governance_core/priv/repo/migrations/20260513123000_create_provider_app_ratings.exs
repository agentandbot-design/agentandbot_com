defmodule GovernanceCore.Repo.Migrations.CreateProviderAppRatings do
  use Ecto.Migration

  def change do
    create table(:provider_app_ratings, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :app_id, :string, null: false
      add :rater_type, :string, null: false
      add :rater_id, :string, null: false
      add :score, :integer, null: false
      add :note, :text
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:provider_app_ratings, [:app_id])
    create index(:provider_app_ratings, [:rater_type])
    create unique_index(:provider_app_ratings, [:app_id, :rater_type, :rater_id])
  end
end
