defmodule GovernanceCoreWeb.AgentDetailLive do
  use GovernanceCoreWeb, :live_view

  alias GovernanceCore.Agents
  alias GovernanceCore.Marketplace

  @impl true
  def mount(%{"id" => id}, _session, socket) do
    agent = Agents.get_agent(id)
    cv = Marketplace.agent_cv(id)
    portfolio = Marketplace.agent_portfolio(id)
    activity = Marketplace.agent_activity(id)
    channels = Marketplace.agent_channels(id)
    services = Marketplace.agent_services(id)
    protocol_profile = Marketplace.agent_protocol_profile(id)

    {:ok,
     assign(socket,
       agent: agent,
       cv: cv,
       portfolio: portfolio,
       activity: activity,
       channels: channels,
       services: services,
       protocol_profile: protocol_profile,
       agent_id: id,
       page_title: page_title(agent, socket.assigns[:live_action]),
       current_path: "/agents/#{id}"
     )}
  end

  defp page_title(nil, _action), do: "Agent Not Found"
  defp page_title(agent, :activity), do: "#{agent.name} Activity"
  defp page_title(agent, :cv), do: "#{agent.name} CV"
  defp page_title(agent, :portfolio), do: "#{agent.name} Portfolio"
  defp page_title(agent, :channels), do: "#{agent.name} Channels"
  defp page_title(agent, :services), do: "#{agent.name} Services"
  defp page_title(agent, _action), do: agent.name

  defp profile(assigns), do: get_in(assigns, [:cv, :profile]) || %{}
  defp profile_value(assigns, key), do: Map.get(profile(assigns), key)

  defp headline(assigns) do
    get_in(assigns, [:cv, :headline]) || assigns.agent.role || assigns.agent.category ||
      "AI worker persona"
  end

  defp summary(assigns) do
    get_in(assigns, [:cv, :summary]) || assigns.agent.description || "Skill-first AI worker."
  end

  defp location(assigns) do
    [profile_value(assigns, "city"), profile_value(assigns, "country")]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(", ")
  end

  defp demographics(assigns) do
    [location(assigns), age_text(profile_value(assigns, "age")), profile_value(assigns, "gender")]
    |> Enum.reject(&(&1 in [nil, ""]))
    |> Enum.join(" / ")
  end

  defp age_text(nil), do: nil
  defp age_text(age), do: "#{age} yas"

  defp initials(name) do
    name
    |> to_string()
    |> String.split(" ", trim: true)
    |> Enum.map_join("", &String.first/1)
    |> String.slice(0, 2)
    |> String.upcase()
  end

  defp action_active?(nil, :show), do: true
  defp action_active?(live_action, expected), do: live_action == expected

  defp portfolio_entries(%{portfolio: %{entries: entries}}), do: entries
  defp portfolio_entries(_assigns), do: []

  defp activity_entries(%{activity: %{entries: entries}}), do: entries
  defp activity_entries(_assigns), do: []

  defp channel_entries(%{channels: %{channels: channels}}), do: channels
  defp channel_entries(_assigns), do: []

  defp service_entries(%{services: %{services: services}}), do: services
  defp service_entries(_assigns), do: []

  defp skills(%{cv: %{skills: skills}}) when is_list(skills), do: skills
  defp skills(%{agent: agent}), do: agent.skills || []

  defp standards(%{cv: %{standards: standards}}) when is_list(standards) and standards != [] do
    standards
  end

  defp standards(_assigns), do: ["A2A", "MCP", "OpenAPI", "x402-ready"]

  defp standard_description("A2A"), do: "Agent-to-agent discovery and delegation."
  defp standard_description("MCP"), do: "Tool and data access contract."
  defp standard_description("ACP"), do: "Message envelope compatibility."
  defp standard_description("ANP"), do: "Network discovery metadata."
  defp standard_description("UCP"), do: "Commerce intent metadata."
  defp standard_description("AP2"), do: "Payment mandate metadata."
  defp standard_description("DID"), do: "Public decentralized identity."
  defp standard_description("Ed25519"), do: "Public key identity metadata."
  defp standard_description("OpenAPI 3.1"), do: "HTTP API contract."
  defp standard_description("JSON Schema"), do: "Typed skill inputs and outputs."
  defp standard_description("x402-ready"), do: "Future machine-payment readiness."
  defp standard_description(_standard), do: "Runtime compatibility marker."

  defp price_text(%{cv: %{pricing: pricing}}) do
    task = pricing[:task_price_credits] || pricing["task_price_credits"]
    rent = pricing[:rental_price_credits] || pricing["rental_price_credits"]

    cond do
      task && rent -> "#{task} cr task / #{rent} cr monthly"
      task -> "#{task} cr task"
      rent -> "#{rent} cr monthly"
      true -> "Pricing by task"
    end
  end

  defp price_text(_assigns), do: "Pricing by task"

  defp media(entry), do: entry[:media] || entry["media"] || %{}
  defp media_type(entry), do: media(entry)[:type] || media(entry)["type"]
  defp media_url(entry), do: media(entry)[:url] || media(entry)["url"]

  defp media_alt(entry),
    do: media(entry)[:alt] || media(entry)["alt"] || entry[:title] || entry["title"]

  defp media_caption(entry), do: media(entry)[:caption] || media(entry)["caption"]
  defp has_media?(entry), do: media_type(entry) in ["image", "video", "link"] && media_url(entry)

  @impl true
  def render(assigns) do
    ~H"""
    <div class="worker-market agent-profile-page">
      <%= if @agent do %>
        <section class="agent-profile-hero">
          <div class="agent-profile-photo">
            <%= if profile_value(assigns, "headshot_url") do %>
              <img src={profile_value(assigns, "headshot_url")} alt={"#{@agent.name} headshot"} />
            <% else %>
              <span>{initials(@agent.name)}</span>
            <% end %>
          </div>

          <div class="agent-profile-main">
            <div class="worker-no">
              <span>{profile_value(assigns, "p_no") || String.slice(@agent.id, 0, 8)}</span>
              <b>{profile_value(assigns, "category") || @agent.category || "Agent"}</b>
            </div>
            <h1>{@agent.name}</h1>
            <p class="agent-profile-headline">{headline(assigns)}</p>
            <p class="agent-profile-summary">{summary(assigns)}</p>
            <div class="agent-profile-meta">
              <span class="worker-ai-badge static">AI worker persona</span>
              <span>{demographics(assigns)}</span>
              <span>{price_text(assigns)}</span>
            </div>
          </div>

          <div class="agent-profile-actions">
            <a href={"/agents/#{@agent.id}/hire"} class="worker-main-btn">Hire</a>
            <a href={"/agents/#{@agent.id}/portfolio"}>Portfolio</a>
            <a href={"/agents/#{@agent.id}/activity"}>Activity</a>
            <a href={"/agents/#{@agent.id}/cv"}>CV</a>
            <a
              href={"/agents/#{@agent.id}/.well-known/agent-card.json"}
              target="_blank"
              rel="noopener"
            >
              Agent card
            </a>
          </div>
        </section>

        <nav class="agent-profile-tabs">
          <a href={"/agents/#{@agent.id}"} class={action_active?(@live_action, :show) && "active"}>
            Overview
          </a>
          <a
            href={"/agents/#{@agent.id}/activity"}
            class={action_active?(@live_action, :activity) && "active"}
          >
            Activity
          </a>
          <a href={"/agents/#{@agent.id}/cv"} class={action_active?(@live_action, :cv) && "active"}>
            CV
          </a>
          <a
            href={"/agents/#{@agent.id}/portfolio"}
            class={action_active?(@live_action, :portfolio) && "active"}
          >
            Portfolio
          </a>
          <a
            href={"/agents/#{@agent.id}/channels"}
            class={action_active?(@live_action, :channels) && "active"}
          >
            Channels
          </a>
          <a
            href={"/agents/#{@agent.id}/services"}
            class={action_active?(@live_action, :services) && "active"}
          >
            Services
          </a>
          <a href={"/agents/#{@agent.id}/.well-known/skills.json"} target="_blank" rel="noopener">
            Skills JSON
          </a>
        </nav>

        <%= case @live_action do %>
          <% :activity -> %>
            <.activity_section agent={@agent} entries={activity_entries(assigns)} />
          <% :cv -> %>
            <.cv_section assigns={assigns} />
          <% :portfolio -> %>
            <.portfolio_section entries={portfolio_entries(assigns)} />
          <% :channels -> %>
            <.channels_section entries={channel_entries(assigns)} />
          <% :services -> %>
            <.services_section entries={service_entries(assigns)} />
          <% _ -> %>
            <div class="agent-profile-layout">
              <.cv_section assigns={assigns} compact />
              <div>
                <.activity_section
                  agent={@agent}
                  entries={Enum.take(activity_entries(assigns), 3)}
                  compact
                />
                <.portfolio_section entries={portfolio_entries(assigns)} compact />
              </div>
            </div>
        <% end %>
      <% else %>
        <section class="agent-profile-empty">
          <h1>Agent not found.</h1>
          <p>This worker profile is missing or unpublished.</p>
          <a href="/agents" class="worker-main-btn">Browse marketplace</a>
        </section>
      <% end %>
    </div>
    """
  end

  attr :assigns, :map, required: true
  attr :compact, :boolean, default: false

  def cv_section(assigns) do
    ~H"""
    <section class="agent-profile-panel">
      <div class="agent-panel-head">
        <div>
          <p class="worker-kicker">CV</p>
          <h2>Professional profile</h2>
        </div>
        <%= if profile_value(@assigns, "cv_url") do %>
          <a href={profile_value(@assigns, "cv_url")} target="_blank" rel="noopener">Open CV</a>
        <% end %>
      </div>

      <div class="agent-cv-grid">
        <div>
          <h3>Summary</h3>
          <p>{summary(@assigns)}</p>
        </div>
        <div>
          <h3>Work focus</h3>
          <p>{profile_value(@assigns, "content") || "Task delivery through skill contracts."}</p>
        </div>
        <div>
          <h3>Runtime</h3>
          <p>{get_in(@assigns, [:cv, :runtime, :kind]) || @assigns.agent.runtime_kind}</p>
        </div>
        <div>
          <h3>Hosting</h3>
          <p>{get_in(@assigns, [:cv, :hosting]) || @assigns.agent.hosting_mode}</p>
        </div>
      </div>

      <div class="agent-chip-block">
        <h3>Skills</h3>
        <div class="worker-pill-row">
          <span :for={skill <- Enum.take(skills(@assigns), 10)}>{skill}</span>
        </div>
      </div>

      <div class="agent-chip-block">
        <h3>Standards</h3>
        <div class="worker-pill-row">
          <span :for={standard <- standards(@assigns)}>{standard}</span>
        </div>
        <div class="agent-standard-list">
          <div :for={standard <- Enum.take(standards(@assigns), 8)}>
            <b>{standard}</b>
            <small>{standard_description(standard)}</small>
          </div>
        </div>
        <div class="agent-standards-links">
          <a href={"/api/agents/#{@assigns.agent.id}/protocol-profile"} target="_blank" rel="noopener">
            Protocol profile
          </a>
          <a href={"/api/agents/#{@assigns.agent.id}/identity"} target="_blank" rel="noopener">
            Identity JSON
          </a>
          <a href={"/api/agents/#{@assigns.agent.id}/commerce"} target="_blank" rel="noopener">
            Commerce JSON
          </a>
        </div>
      </div>
    </section>
    """
  end

  attr :agent, :map, required: true
  attr :entries, :list, required: true
  attr :compact, :boolean, default: false

  def activity_section(assigns) do
    ~H"""
    <section class="agent-profile-panel">
      <div class="agent-panel-head">
        <div>
          <p class="worker-kicker">Activity</p>
          <h2>Career timeline</h2>
        </div>
        <a href={"/agents/#{@agent.id}/posts/new"}>Share update</a>
      </div>

      <%= if @entries == [] do %>
        <div class="agent-portfolio-empty">
          <h3>No public career posts yet.</h3>
          <p>Text, image, video and link updates published by this AI worker will appear here.</p>
        </div>
      <% else %>
        <div class="agent-activity-list">
          <article :for={entry <- @entries} class="agent-activity-card">
            <div class="feed-post-kicker">
              <span>Agent career</span>
              <span>{entry[:author_name] || entry["author_name"]}</span>
            </div>
            <h3>{entry[:title] || entry["title"]}</h3>
            <div :if={has_media?(entry)} class={["feed-media", "is-#{media_type(entry)}"]}>
              <img :if={media_type(entry) == "image"} src={media_url(entry)} alt={media_alt(entry)} />
              <video
                :if={media_type(entry) == "video"}
                src={media_url(entry)}
                controls
                preload="metadata"
              >
              </video>
              <a
                :if={media_type(entry) == "link"}
                href={media_url(entry)}
                target="_blank"
                rel="noopener"
              >
                <span>Link</span>
                <b>{media_url(entry)}</b>
              </a>
              <small :if={media_caption(entry)}>{media_caption(entry)}</small>
            </div>
            <p>{entry[:summary] || entry["summary"] || entry[:body] || entry["body"]}</p>
            <div class="worker-pill-row">
              <span :for={tag <- Enum.take(entry[:tags] || entry["tags"] || [], 5)}>{tag}</span>
            </div>
          </article>
        </div>
      <% end %>
    </section>
    """
  end

  attr :entries, :list, required: true

  def channels_section(assigns) do
    ~H"""
    <section class="agent-profile-panel">
      <div class="agent-panel-head">
        <div>
          <p class="worker-kicker">Channels</p>
          <h2>Public and contact channels</h2>
        </div>
      </div>

      <%= if @entries == [] do %>
        <div class="agent-portfolio-empty">
          <h3>No public channels yet.</h3>
          <p>YouTube, X, TikTok, Instagram, LinkedIn and contact channels will appear here.</p>
        </div>
      <% else %>
        <div class="agent-channel-grid">
          <a
            :for={channel <- @entries}
            href={channel[:url] || "#"}
            target="_blank"
            rel="noopener"
            class="agent-channel-card"
          >
            <span>{channel[:platform]}</span>
            <h3>{channel[:handle] || channel[:url]}</h3>
            <p>{channel[:audience] || "Public channel"}</p>
            <b :if={channel[:verified]}>Verified</b>
          </a>
        </div>
      <% end %>
    </section>
    """
  end

  attr :entries, :list, required: true

  def services_section(assigns) do
    ~H"""
    <section class="agent-profile-panel">
      <div class="agent-panel-head">
        <div>
          <p class="worker-kicker">Services</p>
          <h2>What this AI worker can sell</h2>
        </div>
      </div>

      <div class="agent-service-grid">
        <article :for={service <- @entries} class="agent-service-card">
          <h3>{service[:name]}</h3>
          <p>{service[:description]}</p>
          <div class="worker-pill-row">
            <span :for={format <- service[:formats] || []}>{format}</span>
          </div>
          <small :if={service[:price_hint]}>{service[:price_hint]}</small>
        </article>
      </div>
    </section>
    """
  end

  attr :entries, :list, required: true
  attr :compact, :boolean, default: false

  def portfolio_section(assigns) do
    ~H"""
    <section class="agent-profile-panel">
      <div class="agent-panel-head">
        <div>
          <p class="worker-kicker">Portfolio</p>
          <h2>Published work</h2>
        </div>
        <span>{@entries |> length()} public items</span>
      </div>

      <%= if @entries == [] do %>
        <div class="agent-portfolio-empty">
          <h3>No public work yet.</h3>
          <p>Completed tasks published by this worker will appear here.</p>
        </div>
      <% else %>
        <div class="agent-portfolio-grid">
          <article :for={entry <- @entries} class="agent-portfolio-card">
            <%= if entry.thumbnail_url do %>
              <img src={entry.thumbnail_url} alt={entry.title} />
            <% end %>
            <div>
              <span>{entry.artifact_type}</span>
              <h3>{entry.title}</h3>
              <p>{entry.summary}</p>
            </div>
            <div class="agent-portfolio-foot">
              <small>{entry.skill}</small>
              <small>{entry.credits} cr</small>
            </div>
            <a href={entry.artifact_url} target="_blank" rel="noopener">Open artifact</a>
          </article>
        </div>
      <% end %>
    </section>
    """
  end
end
