defmodule GovernanceCoreWeb.InternalToolDirectoryLive do
  use GovernanceCoreWeb, :live_view

  alias GovernanceCore.InternalTools

  @impl true
  def mount(_params, _session, socket) do
    tools = InternalTools.list_tools()

    {:ok,
     socket
     |> assign(
       all_tools: tools,
       tools: tools,
       stats: tool_stats(tools),
       categories: InternalTools.categories(),
       filters: %{"search" => "", "category" => "all", "agent_access" => "all"},
       page_title: "Internal Tools",
       current_path: "/tools/internal"
     )}
  end

  @impl true
  def handle_event("filter", params, socket) do
    filters =
      Map.merge(socket.assigns.filters, Map.take(params, ["search", "category", "agent_access"]))

    {:noreply,
     assign(socket, filters: filters, tools: filter_tools(socket.assigns.all_tools, filters))}
  end

  defp filter_tools(tools, filters) do
    tools
    |> Enum.filter(fn tool ->
      matches_search?(tool, filters["search"]) and
        matches_category?(tool.category, filters["category"]) and
        matches_agent_access?(tool.agent_access, filters["agent_access"])
    end)
    |> Enum.sort_by(&{status_rank(&1.status), &1.name})
  end

  defp matches_search?(_tool, value) when value in [nil, ""], do: true

  defp matches_search?(tool, value) do
    haystack =
      [
        tool.name,
        tool.slug,
        tool.url,
        tool.container_name,
        tool.category,
        tool.owner,
        Map.get(tool, :notes),
        Enum.join(tool.audience || [], " "),
        Enum.join(tool.allowed_agent_scopes || [], " ")
      ]
      |> Enum.reject(&is_nil/1)
      |> Enum.join(" ")
      |> String.downcase()

    String.contains?(haystack, String.downcase(value))
  end

  defp matches_category?(_category, value) when value in [nil, "", "all"], do: true
  defp matches_category?(category, value), do: category == value

  defp matches_agent_access?(_mode, value) when value in [nil, "", "all"], do: true
  defp matches_agent_access?("false", "yes"), do: false
  defp matches_agent_access?(_mode, "yes"), do: true
  defp matches_agent_access?(mode, value), do: mode == value

  defp status_rank("degraded"), do: 0
  defp status_rank("maintenance"), do: 1
  defp status_rank("active"), do: 2
  defp status_rank(_), do: 3

  defp label(value) do
    value
    |> to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp status_class("active"), do: "badge-success"
  defp status_class("degraded"), do: "badge-warning"
  defp status_class("maintenance"), do: "badge-info"
  defp status_class(_), do: "badge-ghost"

  defp tool_stats(tools) do
    %{
      total: length(tools),
      attention: Enum.count(tools, &(&1.status in ["degraded", "maintenance"])),
      agent_ready: Enum.count(tools, &(&1.agent_access != "false")),
      restricted: Enum.count(tools, &(&1.data_classification == "restricted"))
    }
  end

  defp access_label("false"), do: "Human only"
  defp access_label("true"), do: "Agent ready"
  defp access_label("read_only"), do: "Agent read-only"
  defp access_label("scoped_service_accounts_only"), do: "Scoped agents"
  defp access_label(value), do: label(value || "unknown")

  defp health_label("healthy"), do: "Healthy"
  defp health_label("running"), do: "Running"
  defp health_label("restarting"), do: "Needs attention"
  defp health_label("unknown"), do: "Check needed"
  defp health_label(value), do: label(value || "unknown")

  defp credential_label(nil), do: "Vault reference needed"
  defp credential_label(""), do: "Vault reference needed"
  defp credential_label(_ref), do: "Stored in vault"

  defp action_label("degraded"), do: "Review"
  defp action_label("maintenance"), do: "Review"
  defp action_label(_), do: "Open"

  @impl true
  def render(assigns) do
    ~H"""
    <div id="internal-tool-directory" class="worker-market">
      <header class="worker-hero">
        <div>
          <p class="worker-kicker">e-any.online registry</p>
          <h1>Internal Tools</h1>
          <p class="worker-subtitle">
            Company tools for people and agents. Open what you need, see what needs attention, and keep credentials in the vault.
          </p>
        </div>
        <div class="worker-hero-stat">
          <span>{@stats.total}</span>
          <small>registered</small>
        </div>
      </header>

      <section class="grid grid-cols-1 md:grid-cols-4 gap-4">
        <div class="stats bg-base-200 border border-base-content/10">
          <div class="stat">
            <div class="stat-title text-xs">Needs attention</div>
            <div class="stat-value text-warning text-2xl">{@stats.attention}</div>
          </div>
        </div>
        <div class="stats bg-base-200 border border-base-content/10">
          <div class="stat">
            <div class="stat-title text-xs">Agent ready</div>
            <div class="stat-value text-info text-2xl">{@stats.agent_ready}</div>
          </div>
        </div>
        <div class="stats bg-base-200 border border-base-content/10">
          <div class="stat">
            <div class="stat-title text-xs">Restricted</div>
            <div class="stat-value text-error text-2xl">{@stats.restricted}</div>
          </div>
        </div>
        <div class="stats bg-base-200 border border-base-content/10">
          <div class="stat">
            <div class="stat-title text-xs">Credentials</div>
            <div class="stat-value text-success text-2xl">Vault</div>
          </div>
        </div>
      </section>

      <section class="worker-controls">
        <form phx-change="filter" class="worker-controls-inner">
          <input
            type="search"
            name="search"
            value={@filters["search"]}
            placeholder="Search e-any tools, containers, scopes..."
            class="worker-search"
          />

          <select name="category" class="worker-select">
            <option value="all">Category: All</option>
            <option
              :for={category <- @categories}
              value={category}
              selected={@filters["category"] == category}
            >
              {label(category)}
            </option>
          </select>

          <select name="agent_access" class="worker-select">
            <option value="all" selected={@filters["agent_access"] == "all"}>
              Agent access: All
            </option>
            <option value="yes" selected={@filters["agent_access"] == "yes"}>Agent accessible</option>
            <option value="false" selected={@filters["agent_access"] == "false"}>Humans only</option>
            <option value="read_only" selected={@filters["agent_access"] == "read_only"}>
              Read-only
            </option>
          </select>
        </form>

        <div class="worker-category-row">
          <span class="worker-filter-note">
            Simple rule: UI shows where tools are; vault stores how to log in.
          </span>
          <a href="/tools" class="worker-list-action">Partner tools</a>
          <a href="/api/internal-tools" class="worker-list-action">API</a>
        </div>
      </section>

      <section class="worker-grid tool-grid">
        <article :for={tool <- @tools} class="worker-card tool-card">
          <div class="worker-card-header">
            <div class="worker-avatar tool-avatar">
              <span>{tool.name |> String.first() |> String.upcase()}</span>
            </div>
            <div class="worker-meta">
              <div class="worker-no">
                <span>{label(tool.category)}</span>
                <b>{health_label(tool.health)}</b>
              </div>
              <h2>{tool.name}</h2>
              <p>{Map.get(tool, :notes) || tool.url || "Internal e-any.online tool"}</p>
            </div>
          </div>

          <div class="worker-card-body">
            <div class="worker-pill-row">
              <span class={["badge", status_class(tool.status)]}>{label(tool.status)}</span>
              <span>{access_label(tool.agent_access)}</span>
              <span>{label(tool.data_classification)}</span>
              <span>{tool.container_name || tool.slug}</span>
            </div>
            <div>
              <h3>Who uses it</h3>
              <p>{Enum.join(tool.audience || [], ", ")}</p>
            </div>
            <div>
              <h3>Agent access</h3>
              <p>
                <%= case tool.allowed_agent_scopes || [] do %>
                  <% [] -> %>
                    {access_label(tool.agent_access)}
                  <% scopes -> %>
                    {Enum.join(scopes, ", ")}
                <% end %>
              </p>
            </div>
            <div>
              <h3>Login</h3>
              <p>{credential_label(tool.secrets_ref)}</p>
            </div>
          </div>

          <footer class="worker-card-footer">
            <div class="worker-price">
              <span>Auth</span>
              <b>{label(tool.auth_mode || "unknown")}</b>
            </div>
            <div class="worker-actions">
              <a
                :if={tool.url && String.starts_with?(tool.url, "http")}
                href={tool.url}
                target="_blank"
                rel="noopener"
                class="worker-main-btn"
              >
                {action_label(tool.status)}
              </a>
            </div>
          </footer>
        </article>
      </section>
    </div>
    """
  end
end
