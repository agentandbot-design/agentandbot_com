defmodule GovernanceCoreWeb.AgentCreateLive do
  use GovernanceCoreWeb, :live_view

  alias GovernanceCore.Agents
  alias GovernanceCore.Marketplace
  alias GovernanceCore.RuntimeCatalog

  @categories ["Research", "Finance", "Communication", "Data", "Enterprise", "Custom"]
  @protocols ["A2A + MCP + OpenAPI 3.1", "ABL.ONE/1.0", "ClawSpeak/0.1"]
  @plans [
    %{id: "starter", label: "Starter", detail: "External runtime", price: 0},
    %{id: "team", label: "Team", detail: "Partner hosted", price: 19},
    %{id: "pro", label: "Pro", detail: "Partner hosted", price: 49}
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       step: 1,
       name: "",
       description: "",
       category: "",
       external_endpoint: "",
       external_setup_url: "",
       protocol: "A2A + MCP + OpenAPI 3.1",
       plan: "starter",
       runtime_kind: "hermes",
       hosting_provider: "hostinger",
       categories: @categories,
       protocols: @protocols,
       plans: @plans,
       runtimes: RuntimeCatalog.runtimes(),
       hosting_providers: RuntimeCatalog.hosting_providers(),
       page_title: "Create Agent",
       current_path: "/agents/new"
     )}
  end

  @impl true
  def handle_event("next", _params, %{assigns: %{step: step}} = socket) when step < 3 do
    {:noreply, assign(socket, step: step + 1)}
  end

  @impl true
  def handle_event("back", _params, %{assigns: %{step: step}} = socket) when step > 1 do
    {:noreply, assign(socket, step: step - 1)}
  end

  @impl true
  def handle_event("update_field", %{"field" => "name", "value" => val}, socket) do
    {:noreply, assign(socket, name: val)}
  end

  @impl true
  def handle_event("update_field", %{"field" => "description", "value" => val}, socket) do
    {:noreply, assign(socket, description: val)}
  end

  @impl true
  def handle_event("update_field", %{"field" => "external_endpoint", "value" => val}, socket) do
    {:noreply, assign(socket, external_endpoint: val)}
  end

  @impl true
  def handle_event("update_field", %{"field" => "external_setup_url", "value" => val}, socket) do
    {:noreply, assign(socket, external_setup_url: val)}
  end

  @impl true
  def handle_event("select_category", %{"cat" => cat}, socket) do
    {:noreply, assign(socket, category: cat)}
  end

  @impl true
  def handle_event("select_plan", %{"plan" => plan}, socket) do
    {:noreply, assign(socket, plan: plan)}
  end

  @impl true
  def handle_event("select_runtime", %{"runtime" => runtime_id}, socket) do
    runtime = RuntimeCatalog.get_runtime(runtime_id)
    {:noreply, assign(socket, runtime_kind: runtime.id, protocol: selected_protocol(runtime))}
  end

  @impl true
  def handle_event("select_hosting", %{"provider" => provider}, socket) do
    {:noreply, assign(socket, hosting_provider: provider)}
  end

  @impl true
  def handle_event("launch", _params, socket) do
    runtime = RuntimeCatalog.get_runtime(socket.assigns.runtime_kind)
    hosting = RuntimeCatalog.get_hosting_provider(socket.assigns.hosting_provider)
    plan = selected_plan(socket.assigns.plans, socket.assigns.plan)

    agent_params = %{
      name: socket.assigns.name,
      description: socket.assigns.description,
      category: socket.assigns.category,
      protocol: socket.assigns.protocol,
      type: runtime.id,
      runtime_kind: runtime.id,
      runtime_provider: runtime.name,
      hosting_mode: hosting.mode,
      hosting_url: blank_to_nil(socket.assigns.external_setup_url) || hosting.url,
      interop_standards: runtime.standards,
      skills: runtime.standards,
      owner: "local_user",
      status: "active",
      price_monthly: plan.price,
      metadata: %{
        plan: plan.id,
        hosting_provider: hosting.id,
        hosting_provider_name: hosting.name,
        external_endpoint: blank_to_nil(socket.assigns.external_endpoint),
        external_setup_url: blank_to_nil(socket.assigns.external_setup_url),
        runtime_description: runtime.description,
        execution: "external_hosting_affiliate"
      }
    }

    case Agents.create_agent(agent_params) do
      {:ok, agent} ->
        Marketplace.upsert_policy(%{
          persona_id: agent.id,
          allowed_scopes: ["agents:read", "tasks:assign", "tools:invoke"],
          allowed_skills: runtime.default_skills,
          external_endpoint: blank_to_nil(socket.assigns.external_endpoint)
        })

        {:noreply,
         socket
         |> put_flash(:info, "Agent created. External runtime connection is ready.")
         |> push_navigate(to: "/agents/#{agent.id}")}

      {:error, _changeset} ->
        {:noreply,
         socket
         |> put_flash(:error, "Launch failed. Check required fields.")}
    end
  end

  defp selected_plan(plans, plan_id), do: Enum.find(plans, List.first(plans), &(&1.id == plan_id))

  defp selected_runtime(runtimes, runtime_id),
    do: Enum.find(runtimes, List.first(runtimes), &(&1.id == runtime_id))

  defp selected_hosting_provider(providers, provider_id) do
    Enum.find(providers, List.first(providers), &(&1.id == provider_id))
  end

  defp selected_protocol(%{standards: standards}) do
    cond do
      "A2A" in standards and "MCP" in standards -> "A2A + MCP + OpenAPI 3.1"
      "ClawSpeak" in standards -> "ClawSpeak/0.1"
      true -> "OpenAPI 3.1"
    end
  end

  defp blank_to_nil(""), do: nil
  defp blank_to_nil(value), do: value

  @impl true
  def render(assigns) do
    ~H"""
    <div class="create-wrap">
      <div class="create-progress animate-fade-in">
        <div class={"progress-step #{if @step >= 1, do: "active"}"}>
          <span class="progress-num">1</span>
          <span class="progress-label">Identity</span>
        </div>
        <div class="progress-line"></div>
        <div class={"progress-step #{if @step >= 2, do: "active"}"}>
          <span class="progress-num">2</span>
          <span class="progress-label">Runtime</span>
        </div>
        <div class="progress-line"></div>
        <div class={"progress-step #{if @step >= 3, do: "active"}"}>
          <span class="progress-num">3</span>
          <span class="progress-label">Connect</span>
        </div>
      </div>

      <%= if @step == 1 do %>
        <div class="create-step animate-fade-in-up">
          <h2 class="create-step-title">Name your agent</h2>
          <p class="create-step-sub">Give your agent an identity and purpose.</p>

          <div class="form-group">
            <label class="form-label">Agent Name</label>
            <input
              type="text"
              class="form-input"
              placeholder="e.g. ResearchAgent Pro"
              value={@name}
              phx-keyup="update_field"
              phx-value-field="name"
              phx-debounce="300"
            />
          </div>

          <div class="form-group">
            <label class="form-label">Description</label>
            <textarea
              class="form-textarea"
              placeholder="What does this agent do?"
              phx-keyup="update_field"
              phx-value-field="description"
              phx-debounce="300"
            ><%= @description %></textarea>
          </div>

          <div class="form-group">
            <label class="form-label">Category</label>
            <div class="category-grid">
              <%= for cat <- @categories do %>
                <button
                  class={"category-btn #{if @category == cat, do: "selected"}"}
                  phx-click="select_category"
                  phx-value-cat={cat}
                >
                  {cat}
                </button>
              <% end %>
            </div>
          </div>

          <div class="create-actions">
            <a href="/personas" class="btn-ghost">Cancel</a>
            <button class="btn-primary" phx-click="next">Next</button>
          </div>
        </div>
      <% end %>

      <%= if @step == 2 do %>
        <div class="create-step animate-fade-in-up">
          <h2 class="create-step-title">Choose runtime</h2>
          <p class="create-step-sub">
            AgentAndBot connects the worker; execution stays on external hosting.
          </p>

          <div class="form-group">
            <label class="form-label">Runtime Type</label>
            <div class="size-grid">
              <%= for runtime <- @runtimes do %>
                <button
                  class={"size-card #{if @runtime_kind == runtime.id, do: "selected"}"}
                  phx-click="select_runtime"
                  phx-value-runtime={runtime.id}
                >
                  <div class="size-name">{runtime.name}</div>
                  <div class="size-spec">{runtime.description}</div>
                  <div class="mt-3 flex flex-wrap gap-1">
                    <%= for standard <- runtime.standards do %>
                      <span class="text-[8px] bg-base-content/5 px-2 py-0.5 rounded-full font-bold uppercase">
                        {standard}
                      </span>
                    <% end %>
                  </div>
                </button>
              <% end %>
            </div>
          </div>

          <div class="form-group">
            <label class="form-label">External Hosting</label>
            <div class="size-grid">
              <%= for provider <- @hosting_providers do %>
                <button
                  class={"size-card #{if @hosting_provider == provider.id, do: "selected"}"}
                  phx-click="select_hosting"
                  phx-value-provider={provider.id}
                >
                  <div class="size-name">{provider.name}</div>
                  <div class="size-spec">{provider.description}</div>
                  <div class="size-price">{String.capitalize(provider.mode)}</div>
                </button>
              <% end %>
            </div>
          </div>

          <div class="form-group">
            <label class="form-label">Marketplace Plan</label>
            <div class="size-grid">
              <%= for plan <- @plans do %>
                <button
                  class={"size-card #{if @plan == plan.id, do: "selected"}"}
                  phx-click="select_plan"
                  phx-value-plan={plan.id}
                >
                  <div class="size-name">{plan.label}</div>
                  <div class="size-spec">{plan.detail}</div>
                  <div class="size-price">${plan.price}/mo</div>
                </button>
              <% end %>
            </div>
          </div>

          <div class="form-group">
            <label class="form-label">Execution Endpoint</label>
            <input
              type="url"
              class="form-input"
              value={@external_endpoint}
              placeholder="https://your-agent.example.com/tasks"
              phx-keyup="update_field"
              phx-value-field="external_endpoint"
              phx-debounce="300"
            />
          </div>

          <div class="form-group">
            <label class="form-label">External Setup URL</label>
            <input
              type="url"
              class="form-input"
              value={@external_setup_url}
              placeholder="Affiliate or self-hosted setup link"
              phx-keyup="update_field"
              phx-value-field="external_setup_url"
              phx-debounce="300"
            />
          </div>

          <div class="form-group">
            <label class="form-label">Interoperability</label>
            <div class="proto-badge">
              <span class="status-dot active"></span>
              {@protocol}
            </div>
            <p class="form-hint">Agent cards, MCP tools, OpenAPI schema, delegated task lifecycle.</p>
          </div>

          <div class="create-actions">
            <button class="btn-ghost" phx-click="back">Back</button>
            <button class="btn-primary" phx-click="next">Next</button>
          </div>
        </div>
      <% end %>

      <%= if @step == 3 do %>
        <% runtime = selected_runtime(@runtimes, @runtime_kind) %>
        <% hosting = selected_hosting_provider(@hosting_providers, @hosting_provider) %>
        <% plan = selected_plan(@plans, @plan) %>

        <div class="create-step animate-fade-in-up">
          <h2 class="create-step-title">Review and connect</h2>
          <p class="create-step-sub">
            The agent will be registered here and executed by the selected external runtime.
          </p>

          <div class="review-card">
            <div class="review-header">
              <span class="review-name">{if @name == "", do: "Unnamed Agent", else: @name}</span>
              <span class="status-badge">
                <span class="status-dot idle"></span> Ready
              </span>
            </div>

            <div class="review-rows">
              <div class="review-row">
                <span class="review-key">Category</span>
                <span class="review-val">{if @category == "", do: "-", else: @category}</span>
              </div>
              <div class="review-row">
                <span class="review-key">Runtime</span>
                <span class="review-val">{runtime.name}</span>
              </div>
              <div class="review-row">
                <span class="review-key">Hosting</span>
                <span class="review-val">{hosting.name} ({hosting.mode})</span>
              </div>
              <div class="review-row">
                <span class="review-key">Protocol</span>
                <span class="review-val">{@protocol}</span>
              </div>
              <div class="review-row">
                <span class="review-key">Plan</span>
                <span class="review-val">{plan.label} - ${plan.price}/month</span>
              </div>
            </div>
          </div>

          <div class="create-actions">
            <button class="btn-ghost" phx-click="back">Back</button>
            <button class="btn-hero" phx-click="launch">Create Agent</button>
          </div>
        </div>
      <% end %>
    </div>
    """
  end
end
