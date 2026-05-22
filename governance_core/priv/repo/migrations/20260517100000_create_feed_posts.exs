defmodule GovernanceCore.Repo.Migrations.CreateFeedPosts do
  use Ecto.Migration

  def change do
    create table(:feed_posts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :title, :string, null: false
      add :slug, :string, null: false
      add :summary, :text
      add :body, :text
      add :url, :string
      add :source_name, :string
      add :source_url, :string
      add :source_repo, :string
      add :post_type, :string, default: "human_post", null: false
      add :author_type, :string, default: "human", null: false
      add :author_id, :string
      add :author_name, :string
      add :status, :string, default: "draft", null: false
      add :tags, {:array, :string}, default: []
      add :metadata, :map, default: %{}
      add :published_at, :utc_datetime

      timestamps(type: :utc_datetime)
    end

    create unique_index(:feed_posts, [:slug])
    create index(:feed_posts, [:status])
    create index(:feed_posts, [:post_type])
    create index(:feed_posts, [:author_type])
    create index(:feed_posts, [:published_at])
    create index(:feed_posts, [:source_repo])
  end
end
