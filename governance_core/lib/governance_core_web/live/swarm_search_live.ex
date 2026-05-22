defmodule GovernanceCoreWeb.SwarmSearchLive do
  use GovernanceCoreWeb, :live_view

  alias GovernanceCore.SwarmSearch

  @groups [
    {:agents, "Agents", "hero-user-group"},
    {:tasks, "Tasks", "hero-rectangle-stack"},
    {:feed, "Feed", "hero-newspaper"},
    {:tools, "Tools", "hero-wrench-screwdriver"},
    {:internal_tools, "Internal Tools", "hero-server-stack"},
    {:services, "Services", "hero-credit-card"}
  ]

  def mount(params, _session, socket) do
    query = Map.get(params, "q", "")

    {:ok,
     socket
     |> assign(:page_title, "Swarm Search")
     |> assign(:current_path, "/search")
     |> assign(:groups, @groups)
     |> assign_search(query)}
  end

  def handle_event("search", %{"q" => query}, socket) do
    {:noreply, assign_search(socket, query)}
  end

  def render(assigns) do
    ~H"""
    <div id="swarm-search" class="space-y-8">
      <section class="space-y-4">
        <div class="flex flex-col gap-2">
          <p class="text-xs font-bold uppercase tracking-widest opacity-50">Unified Discovery</p>
          <h1 class="text-3xl font-black tracking-tight">Search the whole swarm</h1>
        </div>

        <form phx-change="search" phx-submit="search" class="relative">
          <.icon
            name="hero-magnifying-glass"
            class="size-5 absolute left-4 top-1/2 -translate-y-1/2 opacity-40"
          />
          <input
            type="search"
            name="q"
            value={@query}
            placeholder="Search agents, tasks, feed posts, tools, internal tools, services..."
            class="input input-bordered w-full h-14 pl-12 text-base bg-base-200 border-base-content/10"
            autofocus
          />
        </form>

        <div class="flex items-center gap-2 text-xs opacity-60">
          <.icon name="hero-sparkles" class="size-4" />
          <span :if={@query == ""}>Start typing to search across the ecosystem.</span>
          <span :if={@query != ""}>{@total} result(s) for “{@query}”</span>
        </div>
      </section>

      <section
        :if={@query != "" and @total == 0}
        class="rounded-lg border border-dashed border-base-content/20 p-10 text-center"
      >
        <.icon name="hero-magnifying-glass-circle" class="size-10 mx-auto opacity-30" />
        <p class="mt-4 font-bold">No matches found</p>
        <p class="text-sm opacity-60 mt-1">
          Try a persona name, skill, task title, feed tag, or service slug.
        </p>
      </section>

      <section :if={@total > 0} class="grid grid-cols-1 xl:grid-cols-2 gap-6">
        <div :for={{key, label, icon} <- @groups} class="space-y-3">
          <div class="flex items-center justify-between px-1">
            <h2 class="text-sm font-bold uppercase tracking-widest opacity-60 flex items-center gap-2">
              <.icon name={icon} class="size-4" /> {label}
            </h2>
            <span class="badge badge-ghost badge-sm">{length(@results.groups[key])}</span>
          </div>

          <div class="space-y-3 min-h-14">
            <.link
              :for={result <- @results.groups[key]}
              navigate={result.url}
              class="block rounded-lg border border-base-content/10 bg-base-200 p-4 hover:bg-base-300 transition-colors"
            >
              <div class="flex items-start justify-between gap-4">
                <div class="min-w-0">
                  <p class="font-black truncate">{result.title}</p>
                  <p class="text-sm opacity-70 mt-1 line-clamp-2">{result.subtitle}</p>
                </div>
                <span class="badge badge-outline badge-sm flex-none">{result.status}</span>
              </div>

              <div :if={result.meta != []} class="flex flex-wrap gap-2 mt-3">
                <span :for={item <- result.meta} class="badge badge-ghost badge-sm">{item}</span>
              </div>
            </.link>

            <div
              :if={@results.groups[key] == []}
              class="rounded-lg border border-dashed border-base-content/10 p-4 text-sm opacity-50"
            >
              No {String.downcase(label)} matches.
            </div>
          </div>
        </div>
      </section>
    </div>
    """
  end

  defp assign_search(socket, query) do
    results = SwarmSearch.search(query)

    socket
    |> assign(:query, results.query)
    |> assign(:results, results)
    |> assign(:total, results.total)
  end
end
