defmodule GovernanceCoreWeb.ProviderAppDirectoryLive do
  use GovernanceCoreWeb, :live_view

  alias GovernanceCore.Marketplace

  @impl true
  def mount(_params, _session, socket) do
    apps = Marketplace.provider_apps()

    {:ok,
     socket
     |> assign(
       all_apps: apps,
       apps: sort_apps(apps),
       categories: Marketplace.provider_app_categories(),
       filters: %{
         "search" => "",
         "category" => "all",
         "deployment" => "all",
         "agent_ready" => "yes"
       },
       page_title: "Agent Tool Directory",
       current_path: "/tools"
     )}
  end

  @impl true
  def handle_event("filter", params, socket) do
    filters =
      socket.assigns.filters
      |> Map.merge(Map.take(params, ["search", "category", "deployment", "agent_ready"]))

    {:noreply,
     assign(socket, filters: filters, apps: filter_apps(socket.assigns.all_apps, filters))}
  end

  @impl true
  def handle_event("rate", %{"app-id" => app_id, "score" => score}, socket) do
    Marketplace.rate_provider_app(app_id, %{
      "score" => score,
      "rater_type" => "human",
      "rater_id" => "local_browser_user"
    })

    apps = Marketplace.provider_apps()

    {:noreply,
     socket
     |> put_flash(:info, "Rating saved.")
     |> assign(all_apps: apps, apps: filter_apps(apps, socket.assigns.filters))}
  end

  defp filter_apps(apps, filters) do
    apps
    |> Enum.filter(fn app ->
      matches_search?(app, filters["search"]) and
        matches_category?(app.category, filters["category"]) and
        matches_deployment?(app, filters["deployment"]) and
        matches_agent_ready?(app, filters["agent_ready"])
    end)
    |> sort_apps()
  end

  defp sort_apps(apps), do: Enum.sort_by(apps, &{if(&1.featured, do: 0, else: 1), &1.name})

  defp matches_search?(_app, value) when value in [nil, ""], do: true

  defp matches_search?(app, value) do
    haystack =
      [
        app.name,
        app.headline,
        app.description,
        app.category,
        Enum.join(app.tags, " "),
        Enum.join(app.capabilities, " "),
        Enum.join(app.best_for, " ")
      ]
      |> Enum.join(" ")
      |> String.downcase()

    String.contains?(haystack, String.downcase(value))
  end

  defp matches_category?(_category, value) when value in [nil, "", "all"], do: true
  defp matches_category?(category, value), do: category == value

  defp matches_deployment?(_app, value) when value in [nil, "", "all"], do: true
  defp matches_deployment?(app, "open_source"), do: app.open_source
  defp matches_deployment?(app, "self_hostable"), do: app.self_hostable
  defp matches_deployment?(app, "saas"), do: not app.self_hostable
  defp matches_deployment?(_app, _value), do: true

  defp matches_agent_ready?(_app, value) when value in [nil, "", "all"], do: true
  defp matches_agent_ready?(app, "yes"), do: app.agent_friendly
  defp matches_agent_ready?(_app, _value), do: true

  defp category_label("one_click_agent_hosting"), do: "One-click agent hosting"
  defp category_label("agent_payments"), do: "Agent payments"
  defp category_label("agent_observability"), do: "Agent observability"
  defp category_label("llm_evals"), do: "LLM evals"
  defp category_label("ai_red_teaming"), do: "AI red teaming"
  defp category_label("agent_testing"), do: "Agent testing"
  defp category_label("llm_security_testing"), do: "LLM security testing"

  defp category_label(value) do
    value
    |> to_string()
    |> String.replace("_", " ")
    |> String.split(" ")
    |> Enum.map_join(" ", &String.capitalize/1)
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div id="agent-tool-directory" class="worker-market">
      <header class="worker-hero">
        <div>
          <p class="worker-kicker">Agent tools and partner apps</p>
          <h1>Find tools for your agent stack</h1>
          <p class="worker-subtitle">
            Observability, evals, red teaming, testing, and security products for people building or renting agents. Partner links can become affiliate links without changing the agent marketplace.
          </p>
        </div>
        <div class="worker-hero-stat">
          <span>{length(@apps)}</span>
          <small>matching tools</small>
        </div>
      </header>

      <section class="worker-controls">
        <form phx-change="filter" class="worker-controls-inner">
          <input
            type="search"
            name="search"
            value={@filters["search"]}
            placeholder="Search tools, risks, frameworks..."
            class="worker-search"
          />

          <select name="category" class="worker-select">
            <option value="all">Category: All</option>
            <option
              :for={category <- @categories}
              value={category}
              selected={@filters["category"] == category}
            >
              {category_label(category)}
            </option>
          </select>

          <select name="deployment" class="worker-select">
            <option value="all" selected={@filters["deployment"] == "all"}>Deploy: All</option>
            <option value="open_source" selected={@filters["deployment"] == "open_source"}>
              Open-source
            </option>
            <option value="self_hostable" selected={@filters["deployment"] == "self_hostable"}>
              Self-hostable
            </option>
            <option value="saas" selected={@filters["deployment"] == "saas"}>SaaS</option>
          </select>

          <select name="agent_ready" class="worker-select">
            <option value="yes" selected={@filters["agent_ready"] == "yes"}>
              Agent-ready only
            </option>
            <option value="all" selected={@filters["agent_ready"] == "all"}>Agent-ready: All</option>
          </select>
        </form>

        <div class="worker-category-row">
          <span class="worker-filter-note">
            Only API/webhook/CLI/SDK/protocol-friendly products by default
          </span>
          <a href="/tools/internal" class="worker-list-action">Internal tools</a>
          <a href="/agents" class="worker-list-action">Back to agents</a>
        </div>
      </section>

      <section class="worker-grid tool-grid">
        <article :for={app <- @apps} class="worker-card tool-card">
          <div class="worker-card-header">
            <div class="worker-avatar tool-avatar">
              <span>{app.name |> String.first() |> String.upcase()}</span>
            </div>
            <div class="worker-meta">
              <div class="worker-no">
                <span>{category_label(app.category)}</span>
                <b>{app.pricing_hint}</b>
              </div>
              <h2>{app.name}</h2>
              <p>{app.headline}</p>
            </div>
          </div>

          <div class="worker-card-body">
            <div>
              <h3>Use case</h3>
              <p>{app.description}</p>
            </div>
            <div>
              <h3>Best for</h3>
              <p>{Enum.join(app.best_for, ", ")}</p>
            </div>
            <div class="worker-pill-row">
              <span :for={capability <- Enum.take(app.capabilities, 4)}>{capability}</span>
            </div>
            <div class="worker-pill-row">
              <span :for={interface <- Enum.take(app.integration_interfaces, 4)}>{interface}</span>
            </div>
            <div class="worker-pill-row">
              <span :if={app.open_source}>Open-source</span>
              <span :if={app.self_hostable}>Self-hostable</span>
              <span :if={app.agent_friendly}>Agent-ready</span>
              <span :if={app.featured}>Featured</span>
            </div>
          </div>

          <footer class="worker-card-footer">
            <div class="worker-price">
              <span>Rating</span>
              <b>{rating_text(app.rating)}</b>
            </div>
            <div class="worker-actions">
              <button
                :for={score <- 1..5}
                type="button"
                phx-click="rate"
                phx-value-app-id={app.id}
                phx-value-score={score}
              >
                {score}
              </button>
              <a
                :if={Map.get(app, :homepage_url)}
                href={Map.get(app, :homepage_url)}
                target={link_target(Map.get(app, :homepage_url))}
                rel="noopener"
              >
                Site
              </a>
              <a
                :if={Map.get(app, :github_url)}
                href={Map.get(app, :github_url)}
                target="_blank"
                rel="noopener"
              >
                GitHub
              </a>
              <a
                :if={Map.get(app, :one_click_install_url)}
                href={Map.get(app, :one_click_install_url)}
                target="_blank"
                rel="noopener"
                class="worker-main-btn"
              >
                1-click
              </a>
              <a
                href={Map.get(app, :affiliate_url) || app.url}
                target={link_target(Map.get(app, :affiliate_url) || app.url)}
                rel="noopener"
                class="worker-main-btn"
              >
                Partner
              </a>
            </div>
          </footer>
        </article>
      </section>
    </div>
    """
  end

  defp rating_text(%{average: nil}), do: "new"
  defp rating_text(%{average: average, count: count}), do: "#{average}/5 (#{count})"

  defp link_target(nil), do: "_self"
  defp link_target(url), do: if(String.starts_with?(url, "http"), do: "_blank", else: "_self")
end
