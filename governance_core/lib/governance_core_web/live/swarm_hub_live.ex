defmodule GovernanceCoreWeb.SwarmHubLive do
  use GovernanceCoreWeb, :live_view
  alias GovernanceCore.Agents

  def mount(_params, _session, socket) do
    stats = Agents.swarm_stats()

    # MOCK DATA for activity (will be linked to AxAudit later)

    recent_activity = [
      %{
        id: 1,
        type: :task_completed,
        persona: "Project Manager",
        text: "Finalized YouTube script draft.",
        time: "2m ago"
      },
      %{
        id: 2,
        type: :payment_challenge,
        persona: "DataScraper",
        text: "Requested 0.45 USDC for LinkedIn extraction.",
        time: "5m ago"
      },
      %{
        id: 3,
        type: :persona_joined,
        persona: "eny.com.tr Bot",
        text: "Now monitoring e-commerce inventory.",
        time: "12m ago"
      }
    ]

    {:ok,
     assign(socket,
       stats: stats,
       recent_activity: recent_activity,
       page_title: "Command Hub",
       current_path: "/"
     )}
  end

  def render(assigns) do
    ~H"""
    <div id="swarm-hub" class="space-y-10">
      <%!-- STATS GRID --%>
      <section id="global-stats" class="grid grid-cols-1 md:grid-cols-4 gap-6">
        <div class="stats shadow bg-base-200 border border-base-content/5">
          <div class="stat">
            <div class="stat-title text-[10px] font-bold uppercase tracking-widest">
              Active Search
            </div>
            <div class="stat-value text-primary leading-none mt-2">{@stats.total}</div>
            <div class="stat-desc text-[10px] mt-1">{@stats.bots} bots / {@stats.humans} humans</div>
          </div>
        </div>

        <div class="stats shadow bg-base-200 border border-base-content/5">
          <div class="stat">
            <div class="stat-title text-[10px] font-bold uppercase tracking-widest">
              Active Scenarios
            </div>
            <div class="stat-value text-secondary leading-none mt-2">{@stats.active_scenarios}</div>
            <div class="stat-desc text-[10px] mt-1 text-secondary">2 in review</div>
          </div>
        </div>

        <div class="stats shadow bg-base-200 border border-base-content/5">
          <div class="stat">
            <div class="stat-title text-[10px] font-bold uppercase tracking-widest">
              Ecospace Spend
            </div>
            <div class="stat-value leading-none mt-2">
              {@stats.spend_cents / 100} <span class="text-xs opacity-50">USDC</span>
            </div>
            <div class="stat-desc text-[10px] mt-1 text-warning">x402 protocol used</div>
          </div>
        </div>

        <div class="stats shadow bg-base-200 border border-base-content/5">
          <div class="stat">
            <div class="stat-title text-[10px] font-bold uppercase tracking-widest">
              Logic Integrity
            </div>
            <div class="stat-value text-success leading-none mt-2">Optimal</div>
            <div class="stat-desc text-[10px] mt-1">99.9% heartbeat response</div>
          </div>
        </div>
      </section>

      <%!-- COMPONENT GRID (MODULAR & UPGRADE-READY) --%>
      <section id="component-grid" class="space-y-4">
        <div class="flex items-center justify-between px-2">
          <h3 class="text-sm font-bold uppercase tracking-widest opacity-50 flex items-center gap-2">
            <.icon name="hero-cpu-chip" class="size-4" /> Component Upgrade Path
          </h3>
          <span class="text-[8px] bg-primary/10 text-primary px-3 py-1 rounded-full font-bold uppercase tracking-wider">
            Markdown Baseline Active
          </span>
        </div>

        <div class="grid grid-cols-2 md:grid-cols-5 gap-4">
          <%!-- BASELINE: ALWAYS THERE --%>
          <div class="bg-primary/5 p-4 rounded-xl border border-primary/20 flex flex-col items-center gap-2 shadow-sm">
            <.icon name="hero-document-text" class="size-6 text-primary" />
            <span class="text-[10px] font-bold uppercase">Markdown</span>
            <span class="text-[8px] opacity-70 font-mono">L0_BASELINE</span>
          </div>

          <%!-- UPGRADES: CONNECTED OR PENDING --%>
          <div class="bg-base-200 p-4 rounded-xl border border-base-content/5 flex flex-col items-center gap-2 opacity-80">
            <.icon name="hero-chat-bubble-left-right" class="size-6 text-success" />
            <span class="text-[10px] font-bold uppercase text-success">Telegram</span>
            <span class="text-[8px] font-mono opacity-50">L1+ CONNECTED</span>
          </div>

          <div class="bg-base-200 p-4 rounded-xl border border-base-content/5 flex flex-col items-center gap-2 opacity-40">
            <.icon name="hero-envelope" class="size-6 text-info" />
            <span class="text-[10px] font-bold uppercase">Email</span>
            <span class="text-[8px] font-mono">L1_AVAILABLE</span>
          </div>

          <div class="bg-base-200 p-4 rounded-xl border border-base-content/5 flex flex-col items-center gap-2 relative overflow-hidden">
            <div class="absolute inset-0 bg-warning/5 animate-pulse"></div>
            <.icon name="hero-bolt" class="size-6 text-warning relative z-10" />
            <span class="text-[10px] font-bold uppercase text-warning relative z-10">Windmill</span>
            <span class="text-[8px] font-mono relative z-10">L2_UPGRADING...</span>
          </div>

          <div class="bg-base-300/30 p-4 rounded-xl border border-dashed border-base-content/10 flex flex-col items-center justify-center gap-1 cursor-pointer hover:bg-base-300/50 transition-all">
            <.icon name="hero-puzzle-piece" class="size-6 opacity-30" />
            <span class="text-[8px] font-bold uppercase opacity-30">Add Upgrade</span>
          </div>
        </div>
      </section>

      <%!-- MAIN DASHBOARD CONTENT --%>
      <div class="grid grid-cols-1 lg:grid-cols-3 gap-10">
        <%!-- RECENT ACTIVITY FEED --%>
        <section id="activity-feed" class="lg:col-span-2 space-y-6">
          <h3 class="text-sm font-bold uppercase tracking-widest opacity-50 px-2 flex items-center gap-2">
            <.icon name="hero-bolt" class="size-4" /> Live Activity
          </h3>

          <div class="space-y-4">
            <div
              :for={item <- @recent_activity}
              class="flex gap-4 p-4 rounded-xl bg-base-200 border border-base-content/5 hover:border-base-content/10 transition-colors"
            >
              <div class="flex-none">
                <div class={[
                  "size-8 rounded-full flex items-center justify-center",
                  item.type == :task_completed && "bg-success/10 text-success",
                  item.type == :payment_challenge && "bg-warning/10 text-warning",
                  item.type == :persona_joined && "bg-info/10 text-info"
                ]}>
                  <.icon
                    name={
                      case item.type do
                        :task_completed -> "hero-check-circle"
                        :payment_challenge -> "hero-currency-dollar"
                        :persona_joined -> "hero-plus-circle"
                      end
                    }
                    class="size-5"
                  />
                </div>
              </div>
              <div class="flex-1">
                <div class="flex items-center justify-between">
                  <p class="text-sm font-bold tracking-tight">{item.persona}</p>
                  <span class="text-[10px] opacity-40">{item.time}</span>
                </div>
                <p class="text-xs opacity-70 mt-0.5">{item.text}</p>
              </div>
            </div>
          </div>
        </section>

        <%!-- QUICK ACTIONS / STATUS --%>
        <section id="quick-links" class="space-y-6">
          <h3 class="text-sm font-bold uppercase tracking-widest opacity-50 px-2 flex items-center gap-2">
            <.icon name="hero-rocket-launch" class="size-4" /> Quick Ops
          </h3>

          <div class="flex flex-col gap-3">
            <.link
              navigate={~p"/search"}
              class="btn btn-block btn-lg bg-base-200 hover:bg-base-300 border-base-content/10 flex items-center justify-between gap-4"
            >
              <div class="flex items-center gap-4">
                <.icon name="hero-magnifying-glass" class="size-6 opacity-50" />
                <div class="text-left">
                  <p class="text-sm font-black">Search Swarm</p>
                  <p class="text-[10px] opacity-50">Search for agents, tasks, logs</p>
                </div>
              </div>
              <.icon name="hero-chevron-right" class="size-4 opacity-50" />
            </.link>

            <.link
              navigate={~p"/agents/new"}
              class="btn btn-block btn-lg bg-base-200 hover:bg-base-300 border-base-content/10 flex items-center justify-between gap-4"
            >
              <div class="flex items-center gap-4">
                <.icon name="hero-plus-circle" class="size-6 opacity-50" />
                <div class="text-left">
                  <p class="text-sm font-black">Spawn Persona</p>
                  <p class="text-[10px] opacity-50">Create new human/bot identity</p>
                </div>
              </div>
              <.icon name="hero-chevron-right" class="size-4 opacity-50" />
            </.link>

            <.link
              navigate={~p"/scenarios"}
              class="btn btn-block btn-lg bg-base-200 hover:bg-base-300 border-base-content/10 flex items-center justify-between gap-4"
            >
              <div class="flex items-center gap-4">
                <.icon name="hero-document-plus" class="size-6 opacity-50" />
                <div class="text-left">
                  <p class="text-sm font-black">Initiate Scenario</p>
                  <p class="text-[10px] opacity-50">Start a hybrid human-agent project</p>
                </div>
              </div>
              <.icon name="hero-chevron-right" class="size-4 opacity-50" />
            </.link>
          </div>
        </section>
      </div>
    </div>
    """
  end
end
