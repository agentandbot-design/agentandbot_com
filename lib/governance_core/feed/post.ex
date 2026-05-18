defmodule GovernanceCore.Feed.Post do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @statuses ~w(draft published archived)
  @post_types ~w(daily_pick human_post agent_post system_news)
  @author_types ~w(system human agent)

  schema "feed_posts" do
    field :title, :string
    field :slug, :string
    field :summary, :string
    field :body, :string
    field :url, :string
    field :source_name, :string
    field :source_url, :string
    field :source_repo, :string
    field :post_type, :string, default: "human_post"
    field :author_type, :string, default: "human"
    field :author_id, :string
    field :author_name, :string
    field :status, :string, default: "draft"
    field :tags, {:array, :string}, default: []
    field :metadata, :map, default: %{}
    field :published_at, :utc_datetime

    has_many :reactions, GovernanceCore.Feed.PostReaction

    timestamps(type: :utc_datetime)
  end

  def changeset(post, attrs) do
    post
    |> cast(attrs, [
      :title,
      :slug,
      :summary,
      :body,
      :url,
      :source_name,
      :source_url,
      :source_repo,
      :post_type,
      :author_type,
      :author_id,
      :author_name,
      :status,
      :tags,
      :metadata,
      :published_at
    ])
    |> normalize_defaults()
    |> validate_required([:title, :slug, :post_type, :author_type, :status])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:post_type, @post_types)
    |> validate_inclusion(:author_type, @author_types)
    |> unique_constraint(:slug)
  end

  defp normalize_defaults(changeset) do
    title = get_field(changeset, :title)

    changeset
    |> put_change_if_blank(:slug, slugify(title || "feed-post"))
    |> put_change_if_blank(:author_name, default_author_name(get_field(changeset, :author_type)))
    |> put_change_if_blank(:status, "draft")
    |> put_change_if_blank(:post_type, default_post_type(get_field(changeset, :author_type)))
  end

  defp default_author_name("agent"), do: "External agent"
  defp default_author_name("system"), do: "AgentAndBot"
  defp default_author_name(_), do: "Anonymous"

  defp default_post_type("agent"), do: "agent_post"
  defp default_post_type(_), do: "human_post"

  defp put_change_if_blank(changeset, field, value) do
    case get_field(changeset, field) do
      nil -> put_change(changeset, field, value)
      "" -> put_change(changeset, field, value)
      _ -> changeset
    end
  end

  def slugify(value) do
    value
    |> to_string()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9]+/u, "-")
    |> String.trim("-")
    |> case do
      "" -> "feed-post"
      slug -> slug
    end
  end
end
