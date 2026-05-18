defmodule GovernanceCoreWeb.FeedShowLive do
  use GovernanceCoreWeb, :live_view

  alias GovernanceCore.Feed

  @impl true
  def mount(%{"slug" => slug}, _session, socket) do
    case Feed.get_post(slug) do
      nil ->
        {:ok, socket |> put_flash(:error, "Feed post not found.") |> push_navigate(to: "/feed")}

      post ->
        {:ok, assign(socket, post: post, page_title: post.title)}
    end
  end

  defp badge("daily_pick"), do: "From awesome-llm-apps"
  defp badge("agent_post"), do: "Agent post"
  defp badge("human_post"), do: "Human post"
  defp badge("system_news"), do: "System news"
  defp badge(value), do: value

  defp published_text(nil), do: "Draft"
  defp published_text(%DateTime{} = value), do: Calendar.strftime(value, "%B %d, %Y")
  defp media(post), do: Feed.media_payload(post)
  defp media_type(post), do: media(post).type
  defp media_url(post), do: media(post).url
  defp media_alt(post), do: media(post).alt || post.title
  defp media_caption(post), do: media(post).caption
  defp has_media?(post), do: media_type(post) in ["image", "video", "link"] && media_url(post)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="worker-market feed-page">
      <article class="feed-article">
        <header class="feed-article-header">
          <p class="worker-kicker">{badge(@post.post_type)}</p>
          <h1>{@post.title}</h1>
          <p>{@post.summary}</p>
          <div class="feed-article-meta">
            <span>{@post.author_name}</span>
            <span>{published_text(@post.published_at)}</span>
            <span>{@post.source_name || @post.source_repo || "AgentAndBot"}</span>
          </div>
        </header>

        <div class="feed-article-body">
          <div :if={has_media?(@post)} class={["feed-media", "is-#{media_type(@post)}", "is-large"]}>
            <img :if={media_type(@post) == "image"} src={media_url(@post)} alt={media_alt(@post)} />
            <video
              :if={media_type(@post) == "video"}
              src={media_url(@post)}
              controls
              preload="metadata"
            >
            </video>
            <a
              :if={media_type(@post) == "link"}
              href={media_url(@post)}
              target="_blank"
              rel="noopener"
            >
              <span>Link</span>
              <b>{media_url(@post)}</b>
            </a>
            <small :if={media_caption(@post)}>{media_caption(@post)}</small>
          </div>

          <p>{@post.body || @post.summary}</p>
        </div>

        <div class="feed-tags">
          <span :for={tag <- @post.tags || []}>{tag}</span>
        </div>

        <footer class="feed-article-actions">
          <a href="/feed">Back to feed</a>
          <a :if={@post.url} href={@post.url} target="_blank" rel="noopener" class="feed-read-link">
            Source
          </a>
          <a
            :if={@post.source_repo}
            href={"https://github.com/#{@post.source_repo}"}
            target="_blank"
            rel="noopener"
          >
            GitHub
          </a>
        </footer>
      </article>
    </div>
    """
  end
end
