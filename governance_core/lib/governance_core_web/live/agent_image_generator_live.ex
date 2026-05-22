defmodule GovernanceCoreWeb.AgentImageGeneratorLive do
  use GovernanceCoreWeb, :live_view

  alias GovernanceCore.Agents
  alias GovernanceCore.AgentImages

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    {:ok,
     assign(socket,
       agent: Agents.get_agent(id),
       agent_id: id,
       actor: "",
       provider_api_key: "",
       image_model: "gemini-3.1-flash-image-preview",
       image_kind: "headshot",
       prompt: "",
       result: nil,
       error: nil,
       page_title: "Generate Agent Image",
       current_path: "/agents/#{id}/images/generate"
     )}
  end

  @impl true
  def handle_event("set", %{"field" => field, "value" => value}, socket) do
    {:noreply, assign(socket, String.to_existing_atom(field), value)}
  rescue
    ArgumentError -> {:noreply, socket}
  end

  @impl true
  def handle_event("generate", _params, socket) do
    attrs = %{
      "actor" => socket.assigns.actor,
      "provider_api_key" => socket.assigns.provider_api_key,
      "image_model" => socket.assigns.image_model,
      "image_kind" => socket.assigns.image_kind,
      "prompt" => socket.assigns.prompt
    }

    case AgentImages.generate_agent_image(socket.assigns.agent_id, attrs) do
      {:ok, result} ->
        {:noreply,
         socket
         |> assign(result: result, error: nil)
         |> put_flash(:info, "Image generated and attached to the agent profile.")}

      {:error, reason} ->
        {:noreply, assign(socket, error: error_text(reason), result: nil)}
    end
  end

  defp error_text(:unauthorized), do: "This user is not allowed to generate agent images."
  defp error_text(:missing_gemini_api_key), do: "GEMINI_API_KEY is not configured on the server."
  defp error_text(:missing_prompt), do: "Prompt is required."
  defp error_text(:invalid_image_kind), do: "Choose headshot or full body."

  defp error_text({:gemini_quota_exceeded, _body}) do
    "Gemini quota or rate limit was reached. Try again later or paste another Gemini API key in the optional key field."
  end

  defp error_text(reason), do: "Image generation failed: #{inspect(reason)}"

  @impl true
  def render(assigns) do
    ~H"""
    <div class="listing-flow">
      <header class="flow-header">
        <p class="market-kicker">Gemini image generation</p>
        <h1>Generate agent image</h1>
        <p>
          Only admin or allowlisted users can generate realistic fictional AI worker persona images.
        </p>
      </header>

      <section class="flow-card">
        <div class="flow-card-body">
          <%= if @agent do %>
            <div class="configure-worker-strip">
              <div class="worker-avatar"><span>{String.first(@agent.name || "A")}</span></div>
              <div>
                <span>AI worker persona</span>
                <strong>{@agent.name}</strong>
                <p>{@agent.description || @agent.role || "Agent profile image generation"}</p>
              </div>
            </div>

            <input
              class="market-input"
              placeholder="Your allowlisted email, e.g. admin@agentandbot.com"
              value={@actor}
              phx-keyup="set"
              phx-value-field="actor"
              phx-debounce="300"
            />

            <input
              class="market-input"
              type="password"
              placeholder="Optional: your own Gemini API key for this generation"
              value={@provider_api_key}
              phx-keyup="set"
              phx-value-field="provider_api_key"
              phx-debounce="300"
            />

            <div class="choice-grid">
              <button
                :for={
                  {label, value} <- [
                    {"Fast image 3.1", "gemini-3.1-flash-image-preview"},
                    {"Fast image 2.5", "gemini-2.5-flash-image"},
                    {"Pro image", "gemini-3-pro-image-preview"}
                  ]
                }
                class={["choice-button", @image_model == value && "is-selected"]}
                phx-click="set"
                phx-value-field="image_model"
                phx-value-value={value}
              >
                {label}
              </button>
            </div>

            <div class="choice-grid">
              <button
                :for={{label, value} <- [{"Headshot", "headshot"}, {"Full body", "full_body"}]}
                class={["choice-button", @image_kind == value && "is-selected"]}
                phx-click="set"
                phx-value-field="image_kind"
                phx-value-value={value}
              >
                {label}
              </button>
            </div>

            <textarea
              class="market-textarea"
              placeholder="Prompt: professional AI worker portrait, realistic but fictional, studio lighting..."
              phx-keyup="set"
              phx-value-field="prompt"
              phx-debounce="300"
            ><%= @prompt %></textarea>

            <%= if @error do %>
              <p class="form-error">{@error}</p>
            <% end %>

            <%= if @result do %>
              <div class="generated-image-preview">
                <img src={@result.image_url} alt="Generated agent image" />
                <p>{@result.image_url}</p>
              </div>
            <% end %>

            <div class="flow-actions">
              <a class="action-muted" href={"/agents/#{@agent_id}"}>Back to profile</a>
              <button class="market-primary-action" phx-click="generate">Generate image</button>
            </div>
          <% else %>
            <p>Agent not found.</p>
          <% end %>
        </div>
      </section>
    </div>
    """
  end
end
