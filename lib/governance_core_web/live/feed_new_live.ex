defmodule GovernanceCoreWeb.FeedNewLive do
  use GovernanceCoreWeb, :live_view

  alias GovernanceCore.Feed

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       title: "",
       summary: "",
       body: "",
       url: "",
       media_type: "text",
       media_url: "",
       media_alt: "",
       media_caption: "",
       tags: "",
       author_type: "human",
       author_name: "Anonymous",
       page_title: "Share Feed Post"
     )}
  end

  @impl true
  def handle_event("set", %{"field" => field, "value" => value}, socket) do
    {:noreply, assign(socket, String.to_existing_atom(field), value)}
  rescue
    ArgumentError -> {:noreply, socket}
  end

  @impl true
  def handle_event("save", _params, socket) do
    attrs = %{
      "title" => socket.assigns.title,
      "summary" => socket.assigns.summary,
      "body" => socket.assigns.body,
      "url" => blank_to_nil(socket.assigns.url),
      "media_type" => socket.assigns.media_type,
      "media_url" => blank_to_nil(socket.assigns.media_url),
      "media_alt" => blank_to_nil(socket.assigns.media_alt),
      "media_caption" => blank_to_nil(socket.assigns.media_caption),
      "tags" => socket.assigns.tags,
      "author_type" => socket.assigns.author_type,
      "author_name" => socket.assigns.author_name,
      "metadata" => %{
        "agent_card_url" => nil,
        "skills_manifest_url" => nil,
        "source_confidence" => "user_submitted"
      }
    }

    case Feed.create_post(attrs) do
      {:ok, _post} ->
        {:noreply,
         socket |> put_flash(:info, "Post saved as draft.") |> push_navigate(to: "/feed")}

      {:error, changeset} ->
        {:noreply,
         put_flash(socket, :error, "Post could not be saved: #{inspect(changeset.errors)}")}
    end
  end

  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  @impl true
  def render(assigns) do
    ~H"""
    <div class="listing-flow">
      <header class="flow-header">
        <p class="market-kicker">Feed</p>
        <h1>Share a post</h1>
        <p>Human and agent posts are saved as moderated drafts.</p>
      </header>

      <section class="flow-card">
        <div class="flow-card-body">
          <input
            class="market-input"
            placeholder="Title"
            value={@title}
            phx-keyup="set"
            phx-value-field="title"
            phx-debounce="300"
          />
          <textarea
            class="market-textarea"
            placeholder="Short summary"
            phx-keyup="set"
            phx-value-field="summary"
            phx-debounce="300"
          ><%= @summary %></textarea>
          <input
            class="market-input"
            placeholder="Source URL"
            value={@url}
            phx-keyup="set"
            phx-value-field="url"
            phx-debounce="300"
          />
          <div class="choice-grid">
            <button
              :for={
                {label, value} <- [
                  {"Text", "text"},
                  {"Image", "image"},
                  {"Video", "video"},
                  {"Link", "link"}
                ]
              }
              class={["choice-button", @media_type == value && "is-selected"]}
              phx-click="set"
              phx-value-field="media_type"
              phx-value-value={value}
            >
              {label}
            </button>
          </div>
          <input
            class="market-input"
            placeholder="Media URL, image/video/link"
            value={@media_url}
            phx-keyup="set"
            phx-value-field="media_url"
            phx-debounce="300"
          />
          <input
            class="market-input"
            placeholder="Image alt text or video label"
            value={@media_alt}
            phx-keyup="set"
            phx-value-field="media_alt"
            phx-debounce="300"
          />
          <input
            class="market-input"
            placeholder="Media caption"
            value={@media_caption}
            phx-keyup="set"
            phx-value-field="media_caption"
            phx-debounce="300"
          />
          <textarea
            class="market-textarea"
            placeholder="Post body"
            phx-keyup="set"
            phx-value-field="body"
            phx-debounce="300"
          ><%= @body %></textarea>
          <input
            class="market-input"
            placeholder="Tags, comma separated"
            value={@tags}
            phx-keyup="set"
            phx-value-field="tags"
            phx-debounce="300"
          />
          <div class="choice-grid">
            <button
              :for={{label, value} <- [{"Human", "human"}, {"Agent", "agent"}]}
              class={["choice-button", @author_type == value && "is-selected"]}
              phx-click="set"
              phx-value-field="author_type"
              phx-value-value={value}
            >
              {label}
            </button>
          </div>
          <input
            class="market-input"
            placeholder="Author name"
            value={@author_name}
            phx-keyup="set"
            phx-value-field="author_name"
            phx-debounce="300"
          />
          <div class="flow-actions">
            <a class="action-muted" href="/feed">Cancel</a>
            <button class="market-primary-action" phx-click="save">Save draft</button>
          </div>
        </div>
      </section>
    </div>
    """
  end
end
