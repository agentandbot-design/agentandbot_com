defmodule GovernanceCore.Feed do
  @moduledoc """
  DB-backed human and agent readable news/blog/feed context.
  """

  import Ecto.Query

  alias GovernanceCore.Feed.{AwesomeLlmAppsImporter, Post, PostReaction, RssImporter}
  alias GovernanceCore.Repo

  def list_posts(opts \\ []) do
    status = Keyword.get(opts, :status, "published")
    type = Keyword.get(opts, :post_type, "all")
    author_type = Keyword.get(opts, :author_type, "all")
    author_id = Keyword.get(opts, :author_id, "all")
    context = Keyword.get(opts, :context, "all")
    source_platform = Keyword.get(opts, :source_platform, "all")
    include_reactions? = Keyword.get(opts, :include_reactions, true)

    Post
    |> maybe_filter_status(status)
    |> maybe_filter_type(type)
    |> maybe_filter_author_type(author_type)
    |> maybe_filter_author_id(author_id)
    |> maybe_filter_context(context)
    |> maybe_filter_source_platform(source_platform)
    |> order_by([p], desc: p.published_at, desc: p.inserted_at)
    |> Repo.all()
    |> maybe_preload_reactions(include_reactions?)
  end

  def get_post(id_or_slug) do
    Post
    |> where([p], p.id == ^id_or_slug or p.slug == ^id_or_slug)
    |> Repo.one()
    |> case do
      nil -> nil
      post -> Repo.preload(post, :reactions)
    end
  end

  def create_post(attrs) do
    attrs =
      attrs
      |> stringify_keys()
      |> normalize_post_attrs()

    %Post{}
    |> Post.changeset(attrs)
    |> Repo.insert()
  end

  def publish_post(id_or_slug) do
    case get_post(id_or_slug) do
      nil ->
        {:error, :post_not_found}

      post ->
        post
        |> Post.changeset(%{
          "status" => "published",
          "published_at" => DateTime.utc_now() |> DateTime.truncate(:second)
        })
        |> Repo.update()
    end
  end

  def rate_post(id_or_slug, attrs) do
    case get_post(id_or_slug) do
      nil ->
        {:error, :post_not_found}

      post ->
        attrs =
          attrs
          |> stringify_keys()
          |> Map.put("post_id", post.id)
          |> Map.put_new("rater_type", "human")
          |> Map.put_new("rater_id", "anonymous")

        %PostReaction{}
        |> PostReaction.changeset(attrs)
        |> Repo.insert(
          on_conflict: {:replace, [:score, :note, :metadata, :updated_at]},
          conflict_target: [:post_id, :rater_type, :rater_id],
          returning: true
        )
    end
  end

  def import_awesome_llm_apps(opts \\ []) do
    AwesomeLlmAppsImporter.import_daily(opts)
  end

  def import_rss(opts \\ []) do
    RssImporter.import(opts)
  end

  def post_payload(%Post{} = post) do
    post = Repo.preload(post, :reactions)

    %{
      id: post.id,
      title: post.title,
      slug: post.slug,
      summary: post.summary,
      body: post.body,
      url: post.url,
      source_name: post.source_name,
      source_url: post.source_url,
      source_repo: post.source_repo,
      post_type: post.post_type,
      author_type: post.author_type,
      author_id: post.author_id,
      author_name: post.author_name,
      status: post.status,
      tags: post.tags || [],
      media: media_payload(post),
      metadata: safe_metadata(post.metadata),
      published_at: post.published_at,
      rating: rating_summary(post.reactions || [])
    }
  end

  def rating_summary(reactions) do
    human = Enum.filter(reactions, &(&1.rater_type == "human"))
    agent = Enum.filter(reactions, &(&1.rater_type == "agent"))

    %{
      average: average_score(reactions),
      count: length(reactions),
      human_average: average_score(human),
      human_count: length(human),
      agent_average: average_score(agent),
      agent_count: length(agent)
    }
  end

  defp maybe_filter_status(query, nil), do: query
  defp maybe_filter_status(query, "all"), do: query
  defp maybe_filter_status(query, status), do: where(query, [p], p.status == ^status)

  defp maybe_filter_type(query, value) when value in [nil, "", "all"], do: query
  defp maybe_filter_type(query, value), do: where(query, [p], p.post_type == ^value)

  defp maybe_filter_author_type(query, value) when value in [nil, "", "all"], do: query
  defp maybe_filter_author_type(query, value), do: where(query, [p], p.author_type == ^value)

  defp maybe_filter_author_id(query, value) when value in [nil, "", "all"], do: query
  defp maybe_filter_author_id(query, value), do: where(query, [p], p.author_id == ^value)

  defp maybe_filter_context(query, value) when value in [nil, "", "all"], do: query

  defp maybe_filter_context(query, value) do
    where(query, [p], fragment("json_extract(?, '$.context') = ?", p.metadata, ^value))
  end

  defp maybe_filter_source_platform(query, value) when value in [nil, "", "all"], do: query

  defp maybe_filter_source_platform(query, value) do
    where(query, [p], fragment("json_extract(?, '$.source_platform') = ?", p.metadata, ^value))
  end

  defp maybe_preload_reactions(posts, true), do: Repo.preload(posts, :reactions)
  defp maybe_preload_reactions(posts, _), do: posts

  defp normalize_post_attrs(attrs) do
    author_type = Map.get(attrs, "author_type", "human")

    attrs
    |> Map.put("status", normalized_status(author_type, Map.get(attrs, "status")))
    |> Map.put("post_type", normalized_post_type(author_type, Map.get(attrs, "post_type")))
    |> Map.put_new("author_name", default_author_name(author_type))
    |> normalize_tags()
    |> normalize_media()
    |> normalize_source()
    |> ensure_slug()
  end

  defp normalized_status(author_type, _status) when author_type in ["human", "agent"], do: "draft"

  defp normalized_status(_author_type, status) when status in ["published", "archived"],
    do: status

  defp normalized_status(_author_type, _status), do: "draft"

  defp normalized_post_type("agent", _post_type), do: "agent_post"
  defp normalized_post_type("human", _post_type), do: "human_post"

  defp normalized_post_type(_author_type, post_type)
       when post_type in ["daily_pick", "system_news"], do: post_type

  defp normalized_post_type(_author_type, _post_type), do: "system_news"

  defp default_author_name("agent"), do: "External agent"
  defp default_author_name("system"), do: "AgentAndBot"
  defp default_author_name(_), do: "Anonymous"

  defp normalize_tags(%{"tags" => tags} = attrs) when is_binary(tags) do
    Map.put(attrs, "tags", split_tags(tags))
  end

  defp normalize_tags(attrs), do: attrs

  defp normalize_media(attrs) do
    metadata = Map.get(attrs, "metadata", %{}) || %{}
    existing_media = Map.get(metadata, "media", %{})

    media =
      existing_media
      |> merge_media_field(attrs, "type", "media_type")
      |> merge_media_field(attrs, "url", "media_url")
      |> merge_media_field(attrs, "thumbnail_url", "media_thumbnail_url")
      |> merge_media_field(attrs, "alt", "media_alt")
      |> merge_media_field(attrs, "caption", "media_caption")
      |> normalize_media_type(attrs)
      |> drop_blank_media()

    if media == %{} do
      attrs
    else
      Map.put(attrs, "metadata", Map.put(metadata, "media", media))
    end
  end

  defp merge_media_field(media, attrs, target_key, source_key) do
    case Map.get(attrs, source_key) do
      value when value in [nil, ""] -> media
      value -> Map.put(media, target_key, value)
    end
  end

  defp normalize_media_type(media, attrs) do
    type =
      media
      |> Map.get("type")
      |> infer_media_type(Map.get(media, "url") || Map.get(attrs, "url"))

    if type in ["text", "image", "video", "link"] do
      Map.put(media, "type", type)
    else
      Map.put(media, "type", "text")
    end
  end

  defp infer_media_type(nil, url), do: infer_media_type("text", url)

  defp infer_media_type("", url), do: infer_media_type("text", url)

  defp infer_media_type(type, _url) when type in ["text", "image", "video", "link"], do: type

  defp infer_media_type(_type, url) when is_binary(url) do
    cond do
      String.match?(url, ~r/\.(png|jpe?g|webp|gif|avif)(\?.*)?$/i) -> "image"
      String.match?(url, ~r/\.(mp4|webm|mov|m4v)(\?.*)?$/i) -> "video"
      url != "" -> "link"
      true -> "text"
    end
  end

  defp infer_media_type(_type, _url), do: "text"

  defp drop_blank_media(media) do
    media
    |> Enum.reject(fn {_key, value} -> value in [nil, ""] end)
    |> Map.new()
  end

  defp normalize_source(attrs) do
    platform = Map.get(attrs, "source_platform")
    handle = Map.get(attrs, "source_handle")

    if platform in [nil, ""] and handle in [nil, ""] do
      attrs
    else
      metadata = Map.get(attrs, "metadata", %{}) || %{}

      source =
        %{}
        |> put_if_present("source_platform", normalize_source_platform(platform))
        |> put_if_present("source_handle", handle)

      Map.put(attrs, "metadata", Map.merge(metadata, source))
    end
  end

  defp normalize_source_platform(nil), do: nil
  defp normalize_source_platform(""), do: nil

  defp normalize_source_platform(value) do
    value
    |> to_string()
    |> String.downcase()
    |> String.replace(~r/[^a-z0-9_\-]+/, "_")
    |> String.trim("_")
  end

  defp put_if_present(map, _key, value) when value in [nil, ""], do: map
  defp put_if_present(map, key, value), do: Map.put(map, key, value)

  defp split_tags(value) do
    value
    |> String.split([",", "#"], trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()
  end

  defp ensure_slug(%{"slug" => slug} = attrs) when slug not in [nil, ""], do: attrs

  defp ensure_slug(%{"title" => title} = attrs) do
    Map.put(attrs, "slug", unique_slug(Post.slugify(title)))
  end

  defp ensure_slug(attrs), do: attrs

  def unique_slug(base, suffix \\ 0) do
    candidate = if suffix == 0, do: base, else: "#{base}-#{suffix}"

    if Repo.exists?(from p in Post, where: p.slug == ^candidate) do
      unique_slug(base, suffix + 1)
    else
      candidate
    end
  end

  defp average_score([]), do: nil

  defp average_score(reactions) do
    reactions
    |> Enum.map(& &1.score)
    |> Enum.sum()
    |> Kernel./(length(reactions))
    |> Float.round(1)
  end

  defp safe_metadata(metadata) when is_map(metadata) do
    Map.drop(metadata, ["private_prompt", "credential", "credentials", "api_key", "secret"])
  end

  defp safe_metadata(_metadata), do: %{}

  def media_payload(%Post{metadata: metadata, url: url}) do
    media =
      metadata
      |> safe_metadata()
      |> Map.get("media", %{})

    type = Map.get(media, "type") || infer_media_type("text", Map.get(media, "url") || url)

    %{
      type: type,
      url: Map.get(media, "url") || url,
      thumbnail_url: Map.get(media, "thumbnail_url"),
      alt: Map.get(media, "alt"),
      caption: Map.get(media, "caption")
    }
  end

  def stringify_keys(map) when is_map(map) do
    Map.new(map, fn {key, value} -> {to_string(key), value} end)
  end
end
