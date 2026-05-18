defmodule GovernanceCore.Repo.Migrations.CreateFeedPostReactions do
  use Ecto.Migration

  def change do
    create table(:feed_post_reactions, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :post_id, references(:feed_posts, type: :binary_id, on_delete: :delete_all), null: false
      add :rater_type, :string, null: false
      add :rater_id, :string, null: false
      add :score, :integer, null: false
      add :note, :text
      add :metadata, :map, default: %{}

      timestamps(type: :utc_datetime)
    end

    create index(:feed_post_reactions, [:post_id])
    create index(:feed_post_reactions, [:rater_type])
    create unique_index(:feed_post_reactions, [:post_id, :rater_type, :rater_id])
  end
end
