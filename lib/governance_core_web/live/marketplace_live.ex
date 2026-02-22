defmodule GovernanceCoreWeb.MarketplaceLive do
  use GovernanceCoreWeb, :live_view

  @agents [
    %{
      id: "research-pro",
      name: "ResearchAgent Pro",
      description: "Scans and summarizes any topic from the web.",
      category: "Research",
      status: :active,
      uptime: "99.8%",
      tasks_done: 1_420,
      price_monthly: 29
    },
    %{
      id: "invoice-agent",
      name: "Invoice Agent",
      description: "Reads invoices from email or Telegram, extracts data, exports to CSV.",
      category: "Finance",
      status: :active,
      uptime: "99.9%",
      tasks_done: 8_203,
      price_monthly: 49
    },
    %{
      id: "expense-agent",
      name: "Expense Agent",
      description: "OCR receipts, categorize expenses, prepare accounting-ready records.",
      category: "Finance",
      status: :active,
      uptime: "99.5%",
      tasks_done: 3_870,
      price_monthly: 39
    },
    %{
      id: "email-agent",
      name: "Email Agent",
      description: "Monitors inbox, drafts replies, routes messages to the right agent.",
      category: "Communication",
      status: :active,
      uptime: "99.7%",
      tasks_done: 12_501,
      price_monthly: 19
    },
    %{
      id: "data-sync",
      name: "DataSync Agent",
      description: "Keeps your databases and spreadsheets in sync automatically.",
      category: "Data",
      status: :idle,
      uptime: "98.1%",
      tasks_done: 642,
      price_monthly: 59
    },
    %{
      id: "sap-agent",
      name: "SAP Close Agent",
      description: "Runs month-end closing tasks in SAP with audit trail.",
      category: "Enterprise",
      status: :active,
      uptime: "99.9%",
      tasks_done: 290,
      price_monthly: 149
    }
  ]

  @impl true
  def mount(_params, _session, socket) do
    {:ok, assign(socket, agents: @agents, filter: "all", page_title: "Marketplace")}
  end

  @impl true
  def handle_event("filter", %{"category" => category}, socket) do
    {:noreply, assign(socket, filter: category)}
  end

  defp filtered_agents(agents, "all"), do: agents

  defp filtered_agents(agents, cat),
    do: Enum.filter(agents, &(String.downcase(&1.category) == String.downcase(cat)))

  defp status_color(:active), do: "#22C55E"
  defp status_color(:idle), do: "#64748B"
  defp status_color(:error), do: "#EF4444"

  defp status_label(:active), do: "Active"
  defp status_label(:idle), do: "Idle"
  defp status_label(:error), do: "Error"

  @impl true
  def render(assigns) do
    ~H"""
    <style>
      *, *::before, *::after { box-sizing: border-box; }
      .mkt-wrap { max-width: 1200px; margin: 0 auto; padding: 48px 40px; }
      .mkt-header { margin-bottom: 40px; }
      .mkt-title { font-size: 28px; font-weight: 700; color: #E6EAF0; letter-spacing: -0.5px; margin: 0 0 6px; }
      .mkt-sub { font-size: 14px; color: #9AA4B2; margin: 0; }
      .mkt-filters { display: flex; gap: 8px; margin-bottom: 32px; flex-wrap: wrap; }
      .filter-btn {
        font-size: 12px; font-weight: 500; padding: 5px 14px;
        border-radius: 4px; border: 1px solid #1F2937; background: transparent;
        color: #9AA4B2; cursor: pointer; transition: all 0.15s; font-family: 'Inter', sans-serif;
      }
      .filter-btn:hover { border-color: #3B82F6; color: #E6EAF0; }
      .filter-btn.active { background: #3B82F6; border-color: #3B82F6; color: #fff; }
      .agents-grid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 16px; }
      .agent-card {
        background: #121826; border: 1px solid #1F2937; border-radius: 8px;
        padding: 20px 20px 16px; display: flex; flex-direction: column; gap: 12px;
        transition: border-color 0.15s;
      }
      .agent-card:hover { border-color: #2D3F5E; }
      .card-top { display: flex; justify-content: space-between; align-items: flex-start; }
      .card-name { font-size: 14px; font-weight: 600; color: #E6EAF0; margin: 0; }
      .card-cat { font-size: 11px; color: #9AA4B2; margin: 4px 0 0; }
      .status-badge { display: flex; align-items: center; gap: 5px; font-size: 11px; font-weight: 500; }
      .status-dot { width: 6px; height: 6px; border-radius: 50%; flex-shrink: 0; }
      .card-desc { font-size: 13px; color: #9AA4B2; line-height: 1.55; }
      .card-stats { display: flex; gap: 20px; }
      .stat { font-size: 11px; }
      .stat-val { color: #E6EAF0; font-family: monospace; font-weight: 600; }
      .stat-lbl { color: #64748B; margin-top: 1px; }
      .card-footer { display: flex; justify-content: space-between; align-items: center; padding-top: 12px; border-top: 1px solid #1F2937; }
      .card-price { font-size: 15px; font-weight: 600; color: #E6EAF0; }
      .price-period { font-size: 11px; color: #64748B; font-weight: 400; }
      .btn-deploy {
        background: #3B82F6; color: #fff; font-size: 12px; font-weight: 500;
        padding: 7px 14px; border-radius: 8px; border: none; cursor: pointer;
        font-family: 'Inter', sans-serif; transition: background 0.15s; text-decoration: none;
      }
      .btn-deploy:hover { background: #2563EB; }
      .empty { text-align: center; padding: 64px 20px; color: #9AA4B2; }
      @media (max-width: 900px) { .agents-grid { grid-template-columns: repeat(2, 1fr); } }
      @media (max-width: 600px) {
        .agents-grid { grid-template-columns: 1fr; }
        .mkt-wrap { padding: 32px 20px; }
      }
    </style>

    <%!-- NAV --%>
    <nav style="display:flex;align-items:center;justify-content:space-between;padding:0 40px;height:60px;border-bottom:1px solid #1F2937;position:sticky;top:0;background:#0B0F14;z-index:100;">
      <a href="/" style="font-size:15px;font-weight:600;color:#E6EAF0;text-decoration:none;letter-spacing:-0.3px;">agentandbot</a>
      <div style="display:flex;gap:28px;">
        <a href="/marketplace" style="font-size:13px;color:#3B82F6;text-decoration:none;">Marketplace</a>
        <a href="/agent/connect" style="font-size:13px;color:#9AA4B2;text-decoration:none;">Protocol</a>
      </div>
      <div style="display:flex;gap:12px;">
        <a href="/login" style="font-size:13px;color:#9AA4B2;text-decoration:none;padding:6px 12px;">Sign In</a>
        <a href="/agents/new" style="background:#3B82F6;color:#fff;font-size:13px;font-weight:500;padding:7px 16px;border-radius:8px;text-decoration:none;">Get Started</a>
      </div>
    </nav>

    <div class="mkt-wrap">
      <div class="mkt-header">
        <h1 class="mkt-title">Agent Marketplace</h1>
        <p class="mkt-sub">Deploy a pre-built agent in one click. No setup required.</p>
      </div>

      <%!-- FILTERS --%>
      <div class="mkt-filters">
        <button class={"filter-btn #{if @filter == "all", do: "active"}"} phx-click="filter" phx-value-category="all">All</button>
        <button class={"filter-btn #{if @filter == "Finance", do: "active"}"} phx-click="filter" phx-value-category="Finance">Finance</button>
        <button class={"filter-btn #{if @filter == "Research", do: "active"}"} phx-click="filter" phx-value-category="Research">Research</button>
        <button class={"filter-btn #{if @filter == "Communication", do: "active"}"} phx-click="filter" phx-value-category="Communication">Communication</button>
        <button class={"filter-btn #{if @filter == "Data", do: "active"}"} phx-click="filter" phx-value-category="Data">Data</button>
        <button class={"filter-btn #{if @filter == "Enterprise", do: "active"}"} phx-click="filter" phx-value-category="Enterprise">Enterprise</button>
      </div>

      <%!-- AGENT GRID --%>
      <div class="agents-grid">
        <%= for agent <- filtered_agents(@agents, @filter) do %>
          <div class="agent-card">
            <div class="card-top">
              <div>
                <p class="card-name"><%= agent.name %></p>
                <p class="card-cat"><%= agent.category %></p>
              </div>
              <div class="status-badge" style={"color: #{status_color(agent.status)}"}>
                <span class="status-dot" style={"background: #{status_color(agent.status)}"}></span>
                <%= status_label(agent.status) %>
              </div>
            </div>

            <p class="card-desc"><%= agent.description %></p>

            <div class="card-stats">
              <div class="stat">
                <div class="stat-val"><%= agent.uptime %></div>
                <div class="stat-lbl">Uptime</div>
              </div>
              <div class="stat">
                <div class="stat-val"><%= :erlang.integer_to_list(agent.tasks_done) |> List.to_string() |> String.replace(~r/(\d)(?=(\d{3})+$)/, "\\1,") %></div>
                <div class="stat-lbl">Tasks done</div>
              </div>
            </div>

            <div class="card-footer">
              <div class="card-price">
                $<%= agent.price_monthly %><span class="price-period">/month</span>
              </div>
              <a href={"/agents/#{agent.id}"} class="btn-deploy">Deploy →</a>
            </div>
          </div>
        <% end %>

        <%= if filtered_agents(@agents, @filter) == [] do %>
          <div class="empty" style="grid-column: 1/-1;">
            <p style="font-size:15px;color:#E6EAF0;margin:0 0 8px;">No agents in this category yet.</p>
            <p style="font-size:13px;margin:0 0 20px;">Be the first to deploy one.</p>
            <a href="/agents/new" class="btn-deploy">Create Agent →</a>
          </div>
        <% end %>
      </div>
    </div>
    """
  end
end
