defmodule GovernanceCoreWeb.AgentHireLive do
  use GovernanceCoreWeb, :live_view

  alias GovernanceCore.Agents
  alias GovernanceCore.Marketplace

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    agent = Agents.get_agent(id)

    {:ok,
     assign(socket,
       agent: agent,
       title: "",
       instructions: "",
       required_skill: first_skill(agent),
       expected_artifact: "",
       budget_credits: "5",
       created_by: "local_user",
       page_title: if(agent, do: "Hire #{agent.name}", else: "Agent Not Found"),
       current_path: "/agents/#{id}/hire"
     )}
  end

  @impl true
  def handle_event("update_field", %{"field" => field, "value" => value}, socket) do
    {:noreply, assign(socket, String.to_existing_atom(field), value)}
  end

  @impl true
  def handle_event("hire", _params, socket) do
    params = %{
      agent_id: socket.assigns.agent.id,
      created_by: socket.assigns.created_by,
      title: socket.assigns.title,
      instructions: socket.assigns.instructions,
      required_skill: socket.assigns.required_skill,
      expected_artifact: socket.assigns.expected_artifact,
      budget_credits: socket.assigns.budget_credits
    }

    case Marketplace.create_task(params) do
      {:ok, task} ->
        {:noreply,
         socket
         |> put_flash(:info, "Task escrowed and queued.")
         |> push_navigate(to: "/scenarios?task=#{task.id}")}

      {:error, :insufficient_credits} ->
        {:noreply, put_flash(socket, :error, "Not enough internal credits for this task.")}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Hire failed: #{inspect(reason)}")}
    end
  end

  defp first_skill(nil), do: ""
  defp first_skill(%{skills: [skill | _]}), do: skill
  defp first_skill(_agent), do: ""

  @impl true
  def render(assigns) do
    ~H"""
    <div class="create-wrap">
      <%= if @agent do %>
        <div class="create-step animate-fade-in-up">
          <h2 class="create-step-title">Hire {@agent.name}</h2>
          <p class="create-step-sub">Create a task and escrow internal credits for delivery.</p>

          <div class="form-group">
            <label class="form-label">Task Title</label>
            <input
              type="text"
              class="form-input"
              value={@title}
              placeholder="e.g. Prepare competitor research brief"
              phx-keyup="update_field"
              phx-value-field="title"
              phx-debounce="300"
            />
          </div>

          <div class="form-group">
            <label class="form-label">Instructions</label>
            <textarea
              class="form-textarea"
              phx-keyup="update_field"
              phx-value-field="instructions"
              phx-debounce="300"
            ><%= @instructions %></textarea>
          </div>

          <div class="form-group">
            <label class="form-label">Required Skill</label>
            <input
              type="text"
              class="form-input"
              value={@required_skill}
              phx-keyup="update_field"
              phx-value-field="required_skill"
              phx-debounce="300"
            />
          </div>

          <div class="form-group">
            <label class="form-label">Expected Artifact</label>
            <input
              type="text"
              class="form-input"
              value={@expected_artifact}
              placeholder="PDF, spreadsheet, website URL, image, report..."
              phx-keyup="update_field"
              phx-value-field="expected_artifact"
              phx-debounce="300"
            />
          </div>

          <div class="form-group">
            <label class="form-label">Budget Credits</label>
            <input
              type="number"
              min="0"
              class="form-input"
              value={@budget_credits}
              phx-keyup="update_field"
              phx-value-field="budget_credits"
              phx-debounce="300"
            />
          </div>

          <div class="create-actions">
            <a href={"/agents/#{@agent.id}"} class="btn-ghost">Back</a>
            <button class="btn-hero" phx-click="hire">Hire for task</button>
          </div>
        </div>
      <% else %>
        <div class="empty-state animate-fade-in-up">
          <p class="empty-title">Agent not found.</p>
          <a href="/personas" class="btn-deploy">Browse agents</a>
        </div>
      <% end %>
    </div>
    """
  end
end
