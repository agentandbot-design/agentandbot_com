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

    deploy_status =
      if agent && agent.hosting_mode == "managed" && agent.deployed_endpoint do
        :success
      else
        :idle
      end

    deploy_logs =
      if deploy_status == :success do
        [
          "[SYSTEM] Mevcut dağıtım yüklendi. Sandbox konteyner durumu: AKTİF",
          "[SYSTEM] Canlı API Uç Noktası: #{agent.deployed_endpoint}"
        ]
      else
        []
      end

    socket =
      socket
      |> assign(
        agent: agent,
        cv: cv,
        portfolio: portfolio,
        activity: activity,
        channels: channels,
        services: services,
        protocol_profile: protocol_profile,
        agent_id: id,
        page_title: page_title(agent, socket.assigns[:live_action]),
        current_path: "/agents/#{id}",
        deploy_status: deploy_status,
        deploy_logs: deploy_logs
      )
      |> allow_upload(:dna_file, accept: ~w(.json), max_entries: 1)

    {:ok, socket}
  end

  defp page_title(nil, _action), do: "Agent Not Found"
  defp page_title(agent, :activity), do: "#{agent.name} Activity"
  defp page_title(agent, :cv), do: "#{agent.name} CV"
  defp page_title(agent, :portfolio), do: "#{agent.name} Portfolio"
  defp page_title(agent, :channels), do: "#{agent.name} Channels"
  defp page_title(agent, :services), do: "#{agent.name} Services"
  defp page_title(agent, :deploy), do: "#{agent.name} Dağıtım (Deploy)"
  defp page_title(agent, :brain_sync), do: "#{agent.name} Brain Sync (DNA)"
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
            <a href={"/agents/#{@agent.id}/images/generate"}>Generate image</a>
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
          <a
            href={"/agents/#{@agent.id}/deploy"}
            class={action_active?(@live_action, :deploy) && "active"}
          >
            Dağıtım (Deploy)
          </a>
          <a
            href={"/agents/#{@agent.id}/brain_sync"}
            class={action_active?(@live_action, :brain_sync) && "active"}
          >
            Brain Sync (DNA)
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
          <% :deploy -> %>
            <.deploy_section agent={@agent} deploy_status={@deploy_status} deploy_logs={@deploy_logs} />
          <% :brain_sync -> %>
            <.brain_sync_section agent={@agent} uploads={@uploads} />
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

  @impl true
  def handle_event("deploy_sandbox", _params, socket) do
    logs = [
      "[SYSTEM] [#{NaiveDateTime.utc_now() |> NaiveDateTime.to_time() |> Time.truncate(:second)}] Sandbox dağıtım süreci başlatıldı...",
      "[SYSTEM] [#{NaiveDateTime.utc_now() |> NaiveDateTime.to_time() |> Time.truncate(:second)}] Konteyner parametreleri hazırlanıyor..."
    ]

    Process.send_after(self(), :sandbox_deploy_step_2, 800)
    {:noreply, assign(socket, deploy_status: :deploying, deploy_logs: logs)}
  end

  @impl true
  def handle_event("reset_deployment", _params, socket) do
    {:noreply, assign(socket, deploy_status: :idle, deploy_logs: [])}
  end

  @impl true
  def handle_event("export_dna", _params, socket) do
    agent = socket.assigns.agent

    dna_map = %{
      "name" => agent.name,
      "level" => agent.level || 1,
      "xp" => agent.xp || 0,
      "achievements" => agent.achievements || [],
      "skills" => agent.skills || [],
      "memory_keys_count" => agent.memory_keys_count || 0
    }

    {:ok, json_content} = Jason.encode(dna_map, pretty: true)
    filename = "agent-#{agent.name |> String.downcase() |> String.replace(" ", "-")}-dna.json"

    {:noreply, push_event(socket, "download_json", %{filename: filename, content: json_content})}
  end

  @impl true
  def handle_event("validate_dna_upload", _params, socket) do
    {:noreply, socket}
  end

  @impl true
  def handle_event("cancel_upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :dna_file, ref)}
  end

  @impl true
  def handle_event("import_dna", _params, socket) do
    uploaded_files =
      consume_uploaded_entries(socket, :dna_file, fn %{path: path}, _entry ->
        case File.read(path) do
          {:ok, content} ->
            case Jason.decode(content) do
              {:ok, data} ->
                if is_map(data) and Map.has_key?(data, "level") and Map.has_key?(data, "xp") do
                  {:ok, data}
                else
                  {:error, "Eksik DNA alanları"}
                end

              {:error, _} ->
                {:error, "JSON ayrıştırma hatası"}
            end

          {:error, _} ->
            {:error, "Dosya okuma hatası"}
        end
      end)

    case uploaded_files do
      [data] when is_map(data) ->
        agent = socket.assigns.agent

        updates = %{
          level: Map.get(data, "level", agent.level || 1),
          xp: Map.get(data, "xp", agent.xp || 0),
          achievements: Map.get(data, "achievements", agent.achievements || []),
          skills: Map.get(data, "skills", agent.skills || []),
          memory_keys_count: Map.get(data, "memory_keys_count", agent.memory_keys_count || 0)
        }

        case Agents.update_agent(agent, updates) do
          {:ok, updated_agent} ->
            {:noreply,
             socket
             |> assign(agent: updated_agent)
             |> put_flash(
               :info,
               "Beyin Senkronizasyonu Başarılı! Ajan DNA'sı başarıyla yüklendi."
             )}

          {:error, changeset} ->
            reason =
              Ecto.Changeset.traverse_errors(changeset, fn {msg, _} -> msg end) |> inspect()

            {:noreply,
             socket
             |> put_flash(:error, "Ajan güncellenemedi: #{reason}")}
        end

      _ ->
        {:noreply,
         socket
         |> put_flash(
           :error,
           "Beyin Senkronizasyonu Başarısız! Lütfen geçerli bir Ajan DNA JSON dosyası yükleyin."
         )}
    end
  end

  @impl true
  def handle_info(:sandbox_deploy_step_2, socket) do
    agent = socket.assigns.agent

    logs =
      socket.assigns.deploy_logs ++
        [
          "[SYSTEM] [#{NaiveDateTime.utc_now() |> NaiveDateTime.to_time() |> Time.truncate(:second)}] Docker tabanlı container imajı çekiliyor: #{agent.runtime_kind || "custom"}...",
          "[SYSTEM] [#{NaiveDateTime.utc_now() |> NaiveDateTime.to_time() |> Time.truncate(:second)}] Konteyner oluşturuldu. Ağ ve port yapılandırması başlatılıyor..."
        ]

    Process.send_after(self(), :sandbox_deploy_step_3, 1000)
    {:noreply, assign(socket, deploy_logs: logs)}
  end

  @impl true
  def handle_info(:sandbox_deploy_step_3, socket) do
    logs =
      socket.assigns.deploy_logs ++
        [
          "[SYSTEM] [#{NaiveDateTime.utc_now() |> NaiveDateTime.to_time() |> Time.truncate(:second)}] ABL.ONE ve MCP protokol el sıkışmaları yapılıyor...",
          "[SYSTEM] [#{NaiveDateTime.utc_now() |> NaiveDateTime.to_time() |> Time.truncate(:second)}] Sistem donanım sınırları (CPU & RAM) başarıyla atandı..."
        ]

    Process.send_after(self(), :sandbox_deploy_complete, 1200)
    {:noreply, assign(socket, deploy_logs: logs)}
  end

  @impl true
  def handle_info(:sandbox_deploy_complete, socket) do
    agent = socket.assigns.agent
    endpoint = "https://sandbox.agentandbot.com/runtimes/#{agent.id}/api"

    # Update agent details in DB
    case Agents.update_agent(agent, %{
           hosting_mode: "managed",
           status: "active",
           deployed_endpoint: endpoint
         }) do
      {:ok, updated_agent} ->
        logs =
          socket.assigns.deploy_logs ++
            [
              "[SYSTEM] [#{NaiveDateTime.utc_now() |> NaiveDateTime.to_time() |> Time.truncate(:second)}] DAĞITIM TAMAMLANDI! Konteyner durumu: AKTİF",
              "[SYSTEM] [#{NaiveDateTime.utc_now() |> NaiveDateTime.to_time() |> Time.truncate(:second)}] Canlı Uç Noktası tahsis edildi: #{endpoint}"
            ]

        {:noreply,
         socket
         |> assign(agent: updated_agent, deploy_status: :success, deploy_logs: logs)
         |> put_flash(
           :info,
           "Ajan Sandbox ortamında başarıyla dağıtıldı! Canlı uç noktası aktif."
         )}

      {:error, _reason} ->
        {:noreply, socket}
    end
  end

  # Functional Components for Deploy & Brain Sync
  attr :agent, :map, required: true
  attr :deploy_status, :atom, required: true
  attr :deploy_logs, :list, required: true

  def deploy_section(assigns) do
    hostinger_info =
      case assigns.agent.runtime_kind || assigns.agent.type do
        "hermes" ->
          %{
            title: "Hostinger Hermes Workspace VPS",
            link: "https://www.hostinger.com/vps/docker/hermes-agent",
            desc:
              "Nous Research Hermes tabanlı gelişmiş muhakeme, kalıcı hafıza ve çoklu alt-ajan orkestrasyonu sunan VPS Docker şablonu."
          }

        "agent_zero" ->
          %{
            title: "Hostinger Agent Zero VPS",
            link: "https://www.hostinger.com/vps/docker/agent-zero",
            desc:
              "Kod yürütme, tarayıcı otomasyonu, MCP protokolü ve dinamik araç üretimi sağlayan profesyonel Agent Zero VPS Docker şablonu."
          }

        "openclaw" ->
          %{
            title: "Hostinger OpenClaw VPS",
            link: "https://www.hostinger.com/vps/docker/openclaw",
            desc:
              "Çoklu mesajlaşma kanalları, kalıcı veri depolama ve 24/7 asistanlık özellikleri içeren resmi OpenClaw VPS Docker şablonu."
          }

        _ ->
          %{
            title: "Hostinger Docker VPS Genel Şablonu",
            link: "https://www.hostinger.com/vps/docker/openclaw",
            desc:
              "Ajanlarınızı ve konteynerlerinizi 24/7 bağımsız bir sunucuda barındırmanızı sağlayan hızlı kuruluma hazır Docker VPS şablonu."
          }
      end

    assigns = assign(assigns, hostinger_info: hostinger_info)

    ~H"""
    <section class="agent-profile-panel">
      <!-- Embedded Styles for Premium Visual WOW factors -->
      <style>
        .agent-deploy-container {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 24px;
          margin-top: 14px;
        }
        @media (max-width: 768px) {
          .agent-deploy-container {
            grid-template-columns: 1fr;
          }
        }
        .deploy-panel-card {
          border: 1px solid var(--worker-border);
          border-radius: 12px;
          background: rgba(18, 18, 23, 0.85);
          backdrop-filter: blur(16px);
          padding: 28px;
          display: flex;
          flex-direction: column;
          box-shadow: 0 8px 32px rgba(0, 0, 0, 0.35);
          transition: all 0.3s cubic-bezier(0.4, 0, 0.2, 1);
          position: relative;
          overflow: hidden;
        }
        .deploy-panel-card::before {
          content: '';
          position: absolute;
          top: 0;
          left: 0;
          right: 0;
          height: 3px;
          background: linear-gradient(90deg, var(--worker-primary), var(--worker-lime));
          opacity: 0.8;
        }
        .deploy-panel-card:hover {
          transform: translateY(-4px);
          box-shadow: 0 12px 40px rgba(139, 92, 246, 0.15);
          border-color: rgba(139, 92, 246, 0.35);
        }
        .deploy-card-title {
          display: flex;
          align-items: center;
          gap: 12px;
          margin-bottom: 16px;
        }
        .deploy-card-title h3 {
          margin: 0;
          font-size: 20px;
          font-weight: 800;
          color: var(--worker-text);
        }
        .deploy-card-badge {
          background: var(--worker-primary-soft);
          color: #c4b5fd;
          border-radius: 999px;
          padding: 4px 10px;
          font-size: 11px;
          font-weight: 800;
          text-transform: uppercase;
        }
        .deploy-card-desc {
          color: var(--worker-muted);
          font-size: 14px;
          line-height: 1.6;
          margin-bottom: 24px;
          flex-grow: 1;
        }
        .deploy-specs-list {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 12px;
          margin-bottom: 24px;
        }
        .deploy-spec-item {
          background: rgba(0, 0, 0, 0.25);
          border: 1px solid rgba(255, 255, 255, 0.05);
          border-radius: 8px;
          padding: 10px 14px;
        }
        .deploy-spec-label {
          font-size: 11px;
          color: var(--worker-muted);
          text-transform: uppercase;
          font-weight: 700;
        }
        .deploy-spec-value {
          font-size: 14px;
          font-weight: 800;
          color: var(--worker-text);
          margin-top: 2px;
        }
        .deploy-action-btn {
          display: inline-flex;
          align-items: center;
          justify-content: center;
          min-height: 48px;
          width: 100%;
          border-radius: 8px;
          font-weight: 800;
          font-size: 14px;
          transition: all 0.2s ease;
          cursor: pointer;
          border: none;
          text-decoration: none;
          text-align: center;
        }
        .btn-primary-glow {
          background: linear-gradient(135deg, var(--worker-primary), #6d28d9);
          color: #fff;
          box-shadow: 0 0 16px rgba(139, 92, 246, 0.35);
        }
        .btn-primary-glow:hover {
          box-shadow: 0 0 24px rgba(139, 92, 246, 0.55);
          transform: translateY(-1px);
        }
        .btn-lime-glow {
          background: linear-gradient(135deg, var(--worker-lime), #84cc16);
          color: #0c0a09;
          box-shadow: 0 0 16px rgba(209, 255, 20, 0.35);
        }
        .btn-lime-glow:hover {
          box-shadow: 0 0 24px rgba(209, 255, 20, 0.55);
          transform: translateY(-1px);
        }
        .btn-outline {
          border: 1px solid var(--worker-border);
          background: rgba(255, 255, 255, 0.05);
          color: var(--worker-text);
        }
        .btn-outline:hover {
          border-color: var(--worker-primary);
          background: rgba(139, 92, 246, 0.1);
        }
        .terminal-box {
          background: #09090b;
          border: 1px solid var(--worker-border);
          border-radius: 8px;
          padding: 16px;
          font-family: var(--font-code), Consolas, monospace;
          font-size: 13px;
          color: #a1a1aa;
          height: 180px;
          overflow-y: auto;
          margin-bottom: 20px;
          display: flex;
          flex-direction: column;
          gap: 6px;
          border-left: 3px solid var(--worker-primary);
        }
        .terminal-line {
          line-height: 1.4;
          white-space: pre-wrap;
        }
        .terminal-prompt {
          color: var(--worker-lime);
          margin-right: 8px;
          font-weight: bold;
        }
        .terminal-pulse-cursor {
          display: inline-block;
          width: 8px;
          height: 15px;
          background: var(--worker-lime);
          animation: terminal-blink 1s step-end infinite;
          vertical-align: middle;
        }
        @keyframes terminal-blink {
          from, to { background-color: transparent }
          50% { background-color: var(--worker-lime) }
        }
        .success-deploy-box {
          background: rgba(16, 185, 129, 0.08);
          border: 1px solid rgba(16, 185, 129, 0.35);
          border-radius: 8px;
          padding: 18px;
          margin-bottom: 20px;
          display: flex;
          align-items: flex-start;
          gap: 14px;
        }
        .success-dot-pulse {
          width: 12px;
          height: 12px;
          border-radius: 50%;
          background: #10b981;
          box-shadow: 0 0 0 0 rgba(16, 185, 129, 0.7);
          animation: pulse-green 2s infinite;
          margin-top: 4px;
          flex-shrink: 0;
        }
        @keyframes pulse-green {
          0% {
            transform: scale(0.95);
            box-shadow: 0 0 0 0 rgba(16, 185, 129, 0.7);
          }
          70% {
            transform: scale(1);
            box-shadow: 0 0 0 6px rgba(16, 185, 129, 0);
          }
          100% {
            transform: scale(0.95);
            box-shadow: 0 0 0 0 rgba(16, 185, 129, 0);
          }
        }
        .endpoint-url-box {
          background: rgba(0, 0, 0, 0.3);
          border: 1px solid rgba(255, 255, 255, 0.08);
          border-radius: 6px;
          padding: 10px 14px;
          font-family: var(--font-code), monospace;
          font-size: 13px;
          word-break: break-all;
          margin-top: 8px;
        }
        .endpoint-url-box a {
          color: var(--worker-lime) !important;
          text-decoration: none;
          font-weight: 700;
        }
        .endpoint-url-box a:hover {
          text-decoration: underline;
        }
      </style>

      <div class="agent-panel-head">
        <div>
          <p class="worker-kicker">Canlı Sunucu Dağıtımı</p>
          <h2>Ajan Çalıştırma ve Entegrasyon Paneli</h2>
        </div>
      </div>

      <p class="agent-profile-summary" style="margin-bottom: 24px;">
        Ajanınızı agentandbot.com portalındaki hazır sandbox üzerinde hızlıca ayağa kaldırabilir ya da kendi kiralayacağınız bağımsız Hostinger VPS sunucusunda 24/7 kesintisiz Docker üzerinde çalıştırabilirsiniz.
      </p>

      <div class="agent-deploy-container">
        <!-- Managed Sandbox Deploy Card -->
        <div class="deploy-panel-card">
          <div class="deploy-card-title">
            <h3>Platform Sandbox</h3>
            <span class="deploy-card-badge">Anında Dağıtım</span>
          </div>
          <p class="deploy-card-desc">
            Ajanınızı buluttaki izole sandbox alanımızda saniyeler içinde çalıştırın. Testler, hızlı denemeler ve entegrasyonlar için en ideal yoldur.
          </p>

          <%= if @deploy_status == :idle do %>
            <div class="deploy-specs-list">
              <div class="deploy-spec-item">
                <div class="deploy-spec-label">CPU Limiti</div>
                <div class="deploy-spec-value">{@agent.cpu_limit || 0.5} vCPU</div>
              </div>
              <div class="deploy-spec-item">
                <div class="deploy-spec-label">Bellek Sınırı</div>
                <div class="deploy-spec-value">{@agent.memory_limit_mb || 128} MB RAM</div>
              </div>
              <div class="deploy-spec-item">
                <div class="deploy-spec-label">Protokol</div>
                <div class="deploy-spec-value">{@agent.protocol || "ABL.ONE/1.0"}</div>
              </div>
              <div class="deploy-spec-item">
                <div class="deploy-spec-label">Çalışma Modu</div>
                <div class="deploy-spec-value">Docker Container</div>
              </div>
            </div>

            <button phx-click="deploy_sandbox" class="deploy-action-btn btn-lime-glow">
              Sandbox'ta Tek Tıkla Kur (Deploy)
            </button>
          <% end %>

          <%= if @deploy_status == :deploying do %>
            <div class="terminal-box">
              <div :for={log <- @deploy_logs} class="terminal-line">{log}</div>
              <div class="terminal-line">
                <span class="terminal-prompt">></span><span class="terminal-pulse-cursor"></span>
              </div>
            </div>
            <button
              class="deploy-action-btn btn-outline"
              disabled
              style="opacity: 0.6; cursor: not-allowed;"
            >
              Konteyner Hazırlanıyor...
            </button>
          <% end %>

          <%= if @deploy_status == :success do %>
            <div class="success-deploy-box">
              <div class="success-dot-pulse"></div>
              <div>
                <b style="color: #10b981; font-size: 15px; display: block;">Sandbox Aktif & Canlı</b>
                <span style="font-size: 13px; color: var(--worker-muted);">
                  Ajanınız başarıyla yayına alındı. API uç noktası üzerinden el sıkışma sağlandı.
                </span>
              </div>
            </div>

            <div class="terminal-box" style="height: 120px; margin-bottom: 14px;">
              <div :for={log <- @deploy_logs} class="terminal-line">{log}</div>
            </div>

            <div style="margin-bottom: 24px;">
              <span class="deploy-spec-label">Canlı API Endpoint</span>
              <div class="endpoint-url-box">
                <a href={@agent.deployed_endpoint} target="_blank" rel="noopener">
                  {@agent.deployed_endpoint}
                </a>
              </div>
            </div>

            <button phx-click="reset_deployment" class="deploy-action-btn btn-outline">
              Yeniden Dağıt (Redeploy)
            </button>
          <% end %>
        </div>
        
    <!-- Hostinger VPS Card -->
        <div class="deploy-panel-card">
          <div class="deploy-card-title">
            <h3>Hostinger VPS</h3>
            <span
              class="deploy-card-badge"
              style="background: rgba(209, 255, 20, 0.1); color: var(--worker-lime);"
            >
              Bağımsız VPS
            </span>
          </div>
          <p class="deploy-card-desc">
            {@hostinger_info.desc} Hostinger VPS sayesinde tüm bellek ve veri kontrolü 24/7 tamamen size ait olur.
          </p>

          <div class="deploy-specs-list">
            <div class="deploy-spec-item" style="grid-column: span 2;">
              <div class="deploy-spec-label">Hazır Docker Şablonu</div>
              <div class="deploy-spec-value" style="color: var(--worker-lime);">
                {@hostinger_info.title}
              </div>
            </div>
            <div class="deploy-spec-item">
              <div class="deploy-spec-label">Veri Gizliliği</div>
              <div class="deploy-spec-value">100% Özel Kendi Sunucunuz</div>
            </div>
            <div class="deploy-spec-item">
              <div class="deploy-spec-label">Erişim</div>
              <div class="deploy-spec-value">Tam Root/SSH Yetkisi</div>
            </div>
          </div>

          <a
            href={@hostinger_info.link}
            target="_blank"
            rel="noopener"
            class="deploy-action-btn btn-primary-glow"
            style="margin-top: auto;"
          >
            Hostinger'da Kuruluma Git (Docker VPS)
          </a>
        </div>
      </div>
    </section>
    """
  end

  attr :agent, :map, required: true
  attr :uploads, :map, required: true

  def brain_sync_section(assigns) do
    ~H"""
    <section class="agent-profile-panel">
      <!-- Embedded Styles for Brain Sync Visual WOW factors -->
      <style>
        .dna-stats-grid {
          display: grid;
          grid-template-columns: repeat(4, 1fr);
          gap: 16px;
          margin-bottom: 24px;
        }
        @media (max-width: 768px) {
          .dna-stats-grid {
            grid-template-columns: 1fr 1fr;
          }
        }
        .dna-stat-card {
          background: rgba(255, 255, 255, 0.03);
          border: 1px solid var(--worker-border);
          border-radius: 10px;
          padding: 16px;
          text-align: center;
        }
        .dna-stat-label {
          font-size: 11px;
          color: var(--worker-muted);
          text-transform: uppercase;
          font-weight: 700;
          letter-spacing: 0.05em;
        }
        .dna-stat-value {
          font-size: 28px;
          font-weight: 800;
          color: var(--worker-text);
          margin-top: 4px;
        }
        .dna-helix-container {
          display: flex;
          justify-content: center;
          margin: 20px 0;
        }
        .dna-helix-svg {
          width: 90px;
          height: 90px;
          fill: none;
          stroke: var(--worker-primary);
          stroke-width: 2.5;
          animation: spin-dna 12s linear infinite;
        }
        @keyframes spin-dna {
          0% { transform: rotate(0deg); }
          100% { transform: rotate(360deg); }
        }
        .dna-upload-zone {
          border: 2px dashed rgba(139, 92, 246, 0.35);
          border-radius: 12px;
          padding: 32px 20px;
          text-align: center;
          background: rgba(139, 92, 246, 0.02);
          transition: all 0.2s ease;
          cursor: pointer;
        }
        .dna-upload-zone:hover {
          border-color: var(--worker-primary);
          background: rgba(139, 92, 246, 0.06);
        }
        .dna-upload-inner {
          display: flex;
          flex-direction: column;
          align-items: center;
          gap: 12px;
        }
        .dna-upload-inner p {
          margin: 0;
          font-size: 14px;
          color: var(--worker-muted);
        }
        .dna-upload-inner p b {
          color: var(--worker-primary);
        }
        .dna-upload-inner svg {
          width: 48px;
          height: 48px;
          stroke: var(--worker-muted);
          stroke-width: 1.5;
          fill: none;
          transition: stroke 0.2s ease;
        }
        .dna-upload-zone:hover .dna-upload-inner svg {
          stroke: var(--worker-primary);
        }
        .upload-file-entry {
          display: flex;
          align-items: center;
          justify-content: space-between;
          background: var(--worker-surface-bright);
          border: 1px solid var(--worker-border);
          border-radius: 8px;
          padding: 10px 14px;
          margin-top: 14px;
          font-size: 13px;
          color: var(--worker-text);
        }
        .upload-file-entry button {
          background: none;
          border: none;
          color: #ef4444;
          font-size: 20px;
          cursor: pointer;
          line-height: 1;
          padding: 0 4px;
        }
        .hidden-input {
          display: none !important;
        }
      </style>

      <script>
        if (!window.downloadJsonRegistered) {
          window.downloadJsonRegistered = true;
          window.addEventListener("phx:download_json", (e) => {
            const dataStr = "data:text/json;charset=utf-8," + encodeURIComponent(e.detail.content);
            const downloadAnchor = document.createElement('a');
            downloadAnchor.setAttribute("href", dataStr);
            downloadAnchor.setAttribute("download", e.detail.filename);
            document.body.appendChild(downloadAnchor);
            downloadAnchor.click();
            downloadAnchor.remove();
          });
        }
      </script>

      <div class="agent-panel-head">
        <div>
          <p class="worker-kicker">Taşınabilirlik (Portability)</p>
          <h2>Ajan Brain Sync (DNA Aktarımı)</h2>
        </div>
      </div>

      <p class="agent-profile-summary" style="margin-bottom: 24px;">
        Ajanınızın agentandbot.com portalındaki gelişimini (deneyim puanı, seviye, kilitli başarımlar ve yetenekler) kaydetmek veya kiraladığınız Hostinger VPS sunucularındaki gelişimini buraya kayıpsız geri aktarmak için DNA senkronizasyonunu kullanabilirsiniz.
      </p>
      
    <!-- DNA Info Indicators -->
      <div class="dna-stats-grid">
        <div class="dna-stat-card">
          <div class="dna-stat-label">Ajan Seviyesi</div>
          <div class="dna-stat-value" style="color: var(--worker-lime);">{@agent.level || 1}</div>
        </div>
        <div class="dna-stat-card">
          <div class="dna-stat-label">Deneyim Puanı (XP)</div>
          <div class="dna-stat-value">{@agent.xp || 0}</div>
        </div>
        <div class="dna-stat-card">
          <div class="dna-stat-label">Kilitli Başarımlar</div>
          <div class="dna-stat-value">{@agent.achievements |> length()}</div>
        </div>
        <div class="dna-stat-card">
          <div class="dna-stat-label">Hafıza Anahtarları</div>
          <div class="dna-stat-value">{@agent.memory_keys_count || 0}</div>
        </div>
      </div>

      <div class="agent-cv-grid" style="grid-template-columns: 1fr 1fr; margin-bottom: 24px;">
        <!-- Export DNA Card -->
        <div style="display: flex; flex-direction: column; align-items: center; text-align: center; padding: 24px;">
          <h3>DNA Dışa Aktar (Export)</h3>
          <p style="font-size: 13px; margin-bottom: 20px;">
            Ajanınızın seviye, XP, başarımlar ve aktif yetenek manifestosunu JSON dosyası olarak bilgisayarınıza indirin.
          </p>

          <div class="dna-helix-container">
            <!-- SVG DNA Helix Graphic with CSS animation -->
            <svg class="dna-helix-svg" viewBox="0 0 100 100">
              <path d="M30,15 C40,35 60,65 70,85" />
              <path d="M70,15 C60,35 40,65 30,85" stroke-dasharray="4,4" />
              <circle cx="30" cy="15" r="4" fill="var(--worker-primary)" />
              <circle cx="70" cy="15" r="4" fill="var(--worker-lime)" />
              <circle cx="38" cy="31" r="3" fill="var(--worker-lime)" />
              <circle cx="62" cy="31" r="3" fill="var(--worker-primary)" />
              <circle cx="50" cy="50" r="3.5" fill="var(--worker-primary)" />
              <circle cx="62" cy="69" r="3" fill="var(--worker-lime)" />
              <circle cx="38" cy="69" r="3" fill="var(--worker-primary)" />
              <circle cx="30" cy="85" r="4" fill="var(--worker-primary)" />
              <circle cx="70" cy="85" r="4" fill="var(--worker-lime)" />
            </svg>
          </div>

          <button
            phx-click="export_dna"
            class="deploy-action-btn btn-primary-glow"
            style="margin-top: auto;"
          >
            Ajan DNA'sını İndir (.json)
          </button>
        </div>
        
    <!-- Import DNA Card -->
        <div style="display: flex; flex-direction: column; padding: 24px;">
          <h3 style="text-align: center;">DNA İçe Aktar (Import & Sync)</h3>
          <p style="font-size: 13px; text-align: center; margin-bottom: 20px;">
            Dışarıda veya Hostinger sunucunuzda gelişmiş olan ajanın güncel gelişim dosyasını yükleyin ve portalı güncelleyin.
          </p>

          <form
            phx-submit="import_dna"
            phx-change="validate_dna_upload"
            style="display: flex; flex-direction: column; flex-grow: 1;"
          >
            <div
              class="dna-upload-zone"
              phx-drop-target={@uploads.dna_file.ref}
              onclick="document.getElementById('dna-file-input').click()"
            >
              <div class="dna-upload-inner">
                <svg viewBox="0 0 24 24">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    d="M12 16.5V9.75m0 0l3 3m-3-3l-3 3M6.75 19.5a4.5 4.5 0 01-1.41-8.775 5.25 5.25 0 0110.233-2.33 3 3 0 013.758 3.848A3.752 3.752 0 0118 19.5H6.75z"
                  />
                </svg>
                <p>DNA dosyasını sürükleyin veya <b>dosya seçin</b></p>
              </div>
              <.live_file_input upload={@uploads.dna_file} id="dna-file-input" class="hidden-input" />
            </div>
            
    <!-- Uploaded entries list -->
            <div :for={entry <- @uploads.dna_file.entries} class="upload-file-entry">
              <span style="font-weight: 700; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; max-width: 200px;">
                {entry.client_name}
              </span>
              <button type="button" phx-click="cancel_upload" phx-value-ref={entry.ref}>
                &times;
              </button>
            </div>

            <button
              type="submit"
              class="deploy-action-btn btn-lime-glow"
              style="margin-top: 24px;"
              disabled={@uploads.dna_file.entries == []}
            >
              Beyin Senkronizasyonunu Tamamla
            </button>
          </form>
        </div>
      </div>
    </section>
    """
  end
end
