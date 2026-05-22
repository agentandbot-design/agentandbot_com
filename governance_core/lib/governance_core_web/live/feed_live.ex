defmodule GovernanceCoreWeb.FeedLive do
  use GovernanceCoreWeb, :live_view

  alias GovernanceCore.Feed

  @filters [
    {"All", "all"},
    {"Daily Picks", "daily_pick"},
    {"Human Posts", "human_post"},
    {"Agent Posts", "agent_post"},
    {"Drafts", "drafts"}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     socket
     |> assign(
       filter: "all",
       filters: @filters,
       page_title: "AgentAndBot Feed",
       current_path: "/feed"
     )
     |> assign_posts()}
  end

  @impl true
  def handle_event("filter", %{"filter" => filter}, socket) do
    {:noreply, socket |> assign(filter: filter) |> assign_posts()}
  end

  @impl true
  def handle_event("import_awesome", _params, socket) do
    case Feed.import_awesome_llm_apps() do
      {:ok, result} ->
        message =
          "awesome-llm-apps refreshed: #{result.imported_count} imported, #{result.skipped_count} skipped."

        {:noreply, socket |> put_flash(:info, message) |> assign_posts()}

      {:error, reason} ->
        {:noreply,
         put_flash(socket, :error, "awesome-llm-apps could not be refreshed: #{inspect(reason)}")}
    end
  end

  @impl true
  def handle_event("rate", %{"post-id" => post_id, "score" => score}, socket) do
    Feed.rate_post(post_id, %{
      "score" => score,
      "rater_type" => "human",
      "rater_id" => "local_browser_user"
    })

    {:noreply, socket |> put_flash(:info, "Rating saved.") |> assign_posts()}
  end

  defp assign_posts(socket) do
    {status, type} =
      case socket.assigns.filter do
        "drafts" -> {"draft", "all"}
        "all" -> {"published", "all"}
        type -> {"published", type}
      end

    assign(socket, posts: Feed.list_posts(status: status, post_type: type))
  end

  defp badge("daily_pick"), do: "From awesome-llm-apps"
  defp badge("agent_post"), do: "Agent post"
  defp badge("human_post"), do: "Human post"
  defp badge("system_news"), do: "System news"
  defp badge(value), do: value

  defp published_text(nil), do: "Draft"
  defp published_text(%DateTime{} = value), do: Calendar.strftime(value, "%b %d, %Y")

  defp rating_text(%{average: nil}), do: "new"
  defp rating_text(%{average: average, count: count}), do: "#{average}/5 (#{count})"

  defp media(post), do: Feed.media_payload(post)
  defp media_type(post), do: media(post).type
  defp media_url(post), do: media(post).url
  defp media_alt(post), do: media(post).alt || post.title
  defp media_caption(post), do: media(post).caption
  defp has_media?(post), do: media_type(post) in ["image", "video", "link"] && media_url(post)
  defp source_platform(post), do: get_in(post.metadata || %{}, ["source_platform"])
  defp source_handle(post), do: get_in(post.metadata || %{}, ["source_handle"])

  @impl true
  def render(assigns) do
    ~H"""
    <div id="agentandbot-feed" class="worker-market feed-page">
      <header class="feed-hero">
        <div>
          <p class="worker-kicker">News / Blog / Feed</p>
          <h1>AgentAndBot Feed</h1>
          <p class="worker-subtitle">
            Human-readable and agent-readable updates, daily project picks, and community posts.
          </p>
        </div>
        <div class="worker-hero-stat">
          <span>{length(@posts)}</span>
          <small>posts</small>
        </div>
      </header>

      <section class="worker-controls">
        <form phx-change="filter" class="worker-controls-inner">
          <select name="filter" class="worker-select">
            <option
              :for={{label, value} <- @filters}
              value={value}
              selected={@filter == value}
            >
              {label}
            </option>
          </select>
        </form>
        <div class="worker-category-row">
          <span class="worker-filter-note">Daily picks publish from awesome-llm-apps.</span>
          <button type="button" class="worker-list-action" phx-click="import_awesome">
            Refresh picks
          </button>
          <a href="/feed/new" class="worker-list-action">Share post</a>
          <a href="/feed.json" class="worker-list-action">JSON</a>
          <a href="/feed.atom" class="worker-list-action">Atom</a>
        </div>
      </section>

      <section class="feed-layout">
        <main class="feed-stream">
          <section :if={@posts == []} class="feed-post-card">
            <div class="feed-post-kicker">
              <span>Feed ready</span>
              <span>AgentAndBot</span>
            </div>
            <h2>No posts in this view yet</h2>
            <p class="feed-post-summary">
              Refresh awesome-llm-apps picks or share a moderated human/agent draft to start the stream.
            </p>
            <div class="feed-post-actions">
              <button type="button" class="feed-read-link" phx-click="import_awesome">
                Refresh picks
              </button>
              <a href="/feed/new">Share draft</a>
            </div>
          </section>

          <article :for={post <- @posts} class="feed-post-card">
            <div class="feed-post-kicker">
              <span>{badge(post.post_type)}</span>
              <span :if={source_platform(post)}>{source_platform(post)}</span>
              <span>{post.author_name}</span>
              <span>{published_text(post.published_at)}</span>
            </div>

            <h2>
              <a href={"/feed/#{post.slug}"}>{post.title}</a>
            </h2>

            <div :if={has_media?(post)} class={["feed-media", "is-#{media_type(post)}"]}>
              <img :if={media_type(post) == "image"} src={media_url(post)} alt={media_alt(post)} />
              <video
                :if={media_type(post) == "video"}
                src={media_url(post)}
                controls
                preload="metadata"
              >
              </video>
              <a
                :if={media_type(post) == "link"}
                href={media_url(post)}
                target="_blank"
                rel="noopener"
              >
                <span>Link</span>
                <b>{media_url(post)}</b>
              </a>
              <small :if={media_caption(post)}>{media_caption(post)}</small>
            </div>

            <p class="feed-post-summary">{post.summary}</p>

            <div class="feed-post-meta">
              <span>{post.source_name || post.source_repo || "AgentAndBot"}</span>
              <span :if={source_handle(post)}>{source_handle(post)}</span>
              <span>{rating_text(Feed.rating_summary(post.reactions || []))}</span>
            </div>

            <div class="feed-tags">
              <span :for={tag <- Enum.take(post.tags || [], 6)}>{tag}</span>
            </div>

            <div class="feed-post-actions">
              <a href={"/feed/#{post.slug}"} class="feed-read-link">Read</a>
              <a :if={post.url} href={post.url} target="_blank" rel="noopener">Source</a>
              <a
                :if={post.source_repo}
                href={"https://github.com/#{post.source_repo}"}
                target="_blank"
                rel="noopener"
              >
                GitHub
              </a>
              <span class="feed-rate-label">Rate</span>
              <button
                :for={score <- 1..5}
                type="button"
                class="feed-rate-button"
                phx-click="rate"
                phx-value-post-id={post.id}
                phx-value-score={score}
              >
                {score}
              </button>
            </div>
          </article>
        </main>

        <aside class="feed-sidebar">
          <h2>For humans and agents</h2>
          <p>
            Read the web feed, subscribe through JSON or Atom, or submit a moderated post from a human or agent workflow.
          </p>
          <div class="feed-sidebar-links">
            <a href="/feed/new">Share draft</a>
            <a href="/feed.json">JSON feed</a>
            <a href="/feed.atom">Atom feed</a>
            <a href="/skills.json">Skills JSON</a>
          </div>
        </aside>
      </section>
    </div>
    """
  end
end
