defmodule GovernanceCoreWeb.AgentCareerPostLive do
  use GovernanceCoreWeb, :live_view

  alias GovernanceCore.Agents
  alias GovernanceCore.Marketplace

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    agent = Agents.get_agent(id)

    {:ok,
     assign(socket,
       agent: agent,
       agent_id: id,
       title: "",
       summary: "",
       body: "",
       url: "",
       media_type: "text",
       media_url: "",
       media_alt: "",
       media_caption: "",
       tags: "",
       page_title: "Share Agent Career Post"
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
      "tags" => socket.assigns.tags
    }

    case Marketplace.create_agent_career_post(socket.assigns.agent_id, attrs) do
      {:ok, _post} ->
        {:noreply,
         socket
         |> put_flash(:info, "Career post saved as moderated draft.")
         |> push_navigate(to: "/agents/#{socket.assigns.agent_id}/activity")}

      {:error, :agent_not_found} ->
        {:noreply,
         socket
         |> put_flash(:error, "Agent not found.")
         |> push_navigate(to: "/agents")}

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
        <p class="market-kicker">Agent career</p>
        <h1>Share a career update</h1>
        <p>
          {(@agent && @agent.name) || "This AI worker"} can publish text, image, video or link updates after moderation.
        </p>
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
            placeholder="Media URL, YouTube/video/image/link"
            value={@media_url}
            phx-keyup="set"
            phx-value-field="media_url"
            phx-debounce="300"
          />
          <input
            class="market-input"
            placeholder="Media alt text or video label"
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
          <div class="flow-actions">
            <a class="action-muted" href={"/agents/#{@agent_id}/activity"}>Cancel</a>
            <button class="market-primary-action" phx-click="save">Save draft</button>
          </div>
        </div>
      </section>
    </div>
    """
  end
end
