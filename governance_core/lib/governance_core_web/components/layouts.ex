defmodule GovernanceCoreWeb.Layouts do
  @moduledoc """
  Layouts and shared UI components for agentandbot.com.
  Provides the shared navbar, footer, and flash messages
  used across all pages.
  """
  use GovernanceCoreWeb, :html

  embed_templates("layouts/*")

  # ── Shared App Layout ──────────────────────────────────────
  @doc """
  Renders the main app layout with shared navbar and footer.

  ## Examples

      <Layouts.app flash={@flash}>
        <h1>Content</h1>
      </Layouts.app>

  """
  attr(:flash, :map, required: true, doc: "the map of flash messages")

  attr(:current_scope, :map,
    default: nil,
    doc: "the current scope"
  )

  attr(:current_path, :string,
    default: "/",
    doc: "the current request path for active nav highlighting"
  )

  slot(:inner_block, required: true)

  def app(assigns) do
    ~H"""
    <div class="flex h-screen bg-base-300 font-sans text-base-content overflow-hidden">
      <%!-- SIDEBAR (Navigation & Entity Switcher) --%>
      <aside
        id="main-sidebar"
        class="w-64 flex-none border-r border-base-content/5 flex flex-col bg-base-200"
      >
        <div class="p-6 border-b border-base-content/5 flex items-center justify-between">
          <a href="/" class="text-xl font-black tracking-tight text-primary">swarm.os</a>
          <.icon name="hero-command-line" class="size-5 opacity-50" />
        </div>
        <%!-- ENTITY SWITCHER --%>
        <div class="px-4 py-4 border-b border-base-content/5">
          <div class="dropdown w-full">
            <div
              tabindex="0"
              role="button"
              class="btn btn-ghost btn-sm w-full justify-between border border-base-content/10"
            >
              <div class="flex items-center gap-2 overflow-hidden">
                <div class="size-4 rounded-full bg-primary flex-none"></div>
                <span class="truncate">Harezm Group</span>
              </div>
              <.icon name="hero-chevron-up-down-mini" class="size-4 opacity-50" />
            </div>

            <ul
              tabindex="0"
              class="dropdown-content z-[1] menu p-2 shadow bg-base-100 rounded-box w-52 mt-2"
            >
              <li><a>eny.com.tr</a></li>

              <li><a>YouTube Hub</a></li>

              <li><a>ipcioglu Commerce</a></li>

              <div class="divider my-1"></div>

              <li><a class="text-xs">+ New Entity</a></li>
            </ul>
          </div>
        </div>
        <%!-- MAIN NAV --%>
        <nav class="flex-1 overflow-y-auto px-4 py-6 space-y-1">
          <div class="text-[10px] font-bold uppercase opacity-40 px-2 mb-2 tracking-widest">Main</div>

          <.link
            navigate={~p"/"}
            class={[
              "flex items-center gap-3 px-3 py-2 rounded-lg transition-colors text-sm font-medium hover:bg-base-content/5",
              active_path?(@current_path, "/") &&
                "bg-primary text-primary-content hover:bg-primary/90"
            ]}
          >
            <.icon name="hero-squares-2x2" class="size-5" /> <span>Command Hub</span>
          </.link>
          <.link
            navigate={~p"/search"}
            class={[
              "flex items-center gap-3 px-3 py-2 rounded-lg transition-colors text-sm font-medium hover:bg-base-content/5",
              active_path?(@current_path, "/search") &&
                "bg-primary text-primary-content hover:bg-primary/90"
            ]}
          >
            <.icon name="hero-magnifying-glass" class="size-5" /> <span>Search</span>
          </.link>
          <.link
            navigate={~p"/personas"}
            class={[
              "flex items-center gap-3 px-3 py-2 rounded-lg transition-colors text-sm font-medium hover:bg-base-content/5",
              active_path?(@current_path, ["/agents", "/personas"]) &&
                "bg-primary text-primary-content hover:bg-primary/90"
            ]}
          >
            <.icon name="hero-user-group" class="size-5" /> <span>Personas</span>
          </.link>
          <.link
            navigate={~p"/tools"}
            class={[
              "flex items-center gap-3 px-3 py-2 rounded-lg transition-colors text-sm font-medium hover:bg-base-content/5",
              active_path?(@current_path, "/tools") &&
                "bg-primary text-primary-content hover:bg-primary/90"
            ]}
          >
            <.icon name="hero-wrench-screwdriver" class="size-5" /> <span>Tool Directory</span>
          </.link>
          <.link
            navigate={~p"/tools/internal"}
            class={[
              "flex items-center gap-3 px-3 py-2 rounded-lg transition-colors text-sm font-medium hover:bg-base-content/5",
              active_path?(@current_path, "/tools/internal") &&
                "bg-primary text-primary-content hover:bg-primary/90"
            ]}
          >
            <.icon name="hero-server-stack" class="size-5" /> <span>Internal Tools</span>
          </.link>
          <.link
            navigate={~p"/feed"}
            class={[
              "flex items-center gap-3 px-3 py-2 rounded-lg transition-colors text-sm font-medium hover:bg-base-content/5",
              active_path?(@current_path, "/feed") &&
                "bg-primary text-primary-content hover:bg-primary/90"
            ]}
          >
            <.icon name="hero-newspaper" class="size-5" /> <span>Feed</span>
          </.link>
          <.link
            navigate={~p"/scenarios"}
            class={[
              "flex items-center gap-3 px-3 py-2 rounded-lg transition-colors text-sm font-medium hover:bg-base-content/5",
              active_path?(@current_path, "/scenarios") &&
                "bg-primary text-primary-content hover:bg-primary/90"
            ]}
          >
            <.icon name="hero-rectangle-stack" class="size-5" /> <span>Scenarios</span>
          </.link>
          <div class="text-[10px] font-bold uppercase opacity-40 px-2 mt-8 mb-2 tracking-widest">
            Financials
          </div>

          <.link
            navigate={~p"/governance"}
            class={[
              "flex items-center gap-3 px-3 py-2 rounded-lg transition-colors text-sm font-medium hover:bg-base-content/5",
              active_path?(@current_path, "/governance") &&
                "bg-primary text-primary-content hover:bg-primary/90"
            ]}
          >
            <.icon name="hero-wallet" class="size-5" /> <span>Wallet & AP2</span>
          </.link>
          <.link
            navigate={~p"/payment/dashboard"}
            class={[
              "flex items-center gap-3 px-3 py-2 rounded-lg transition-colors text-sm font-medium hover:bg-base-content/5",
              active_path?(@current_path, "/payment") &&
                "bg-primary text-primary-content hover:bg-primary/90"
            ]}
          >
            <.icon name="hero-chart-bar-square" class="size-5" /> <span>Payments</span>
          </.link>
        </nav>
        <%!-- FOOTER NAV --%>
        <div class="p-4 border-t border-base-content/5 space-y-4">
          <div class="flex items-center justify-between px-2">
            <span class="text-[10px] font-mono opacity-50 uppercase">v0.1.0-alpha</span>
            <.theme_toggle />
          </div>

          <div class="flex items-center gap-3 p-2 rounded-lg bg-base-300 border border-base-content/5">
            <div class="avatar placeholder">
              <div class="bg-primary text-primary-content w-8 rounded-full">
                <span class="text-xs">U</span>
              </div>
            </div>

            <div class="flex-1 overflow-hidden">
              <p class="text-xs font-bold truncate">User Persona</p>

              <p class="text-[10px] opacity-50 truncate">admin@harezm.com</p>
            </div>

            <button class="btn btn-ghost btn-xs btn-circle">
              <.icon name="hero-cog-6-tooth" class="size-4" />
            </button>
          </div>
        </div>
      </aside>
      <%!-- MAIN CONTENT AREA --%>
      <div class="flex-1 flex flex-col min-w-0 bg-base-100 relative">
        <%!-- TOP HEADER (Page Specific Info) --%>
        <header class="h-16 flex-none border-b border-base-content/5 flex items-center justify-between px-8 bg-base-100/50 backdrop-blur-md sticky top-0 z-10">
          <h2 class="text-lg font-bold tracking-tight">
            {page_heading(assigns)}
          </h2>

          <div class="flex items-center gap-4">
            <div class="badge badge-outline border-base-content/10 gap-2 px-3 py-3">
              <div class="size-2 rounded-full bg-success animate-pulse"></div>
              <span class="text-[10px] font-bold uppercase tracking-wider">System Live</span>
            </div>

            <button
              class="btn btn-ghost btn-sm btn-circle relative"
              onclick="document.getElementById('chat-drawer').classList.toggle('open')"
            >
              <.icon name="hero-chat-bubble-left-right" class="size-5" />
              <span class="absolute top-1 right-1 size-2 bg-primary rounded-full"></span>
            </button>
          </div>
        </header>
        <%!-- SCROLLABLE CONTENT --%>
        <main class="flex-1 overflow-y-auto overflow-x-hidden p-8">
          <div class="max-w-6xl mx-auto">
            <%= if Map.has_key?(assigns, :inner_block) do %>
              {render_slot(@inner_block)}
            <% else %>
              {@inner_content}
            <% end %>
          </div>
        </main>
      </div>
      <%!-- CHAT DRAWER (Persistent) --%>
      <aside
        id="chat-drawer"
        class="w-80 flex-none border-l border-base-content/5 flex flex-col bg-base-200 transition-all duration-300 translate-x-full fixed right-0 inset-y-0 z-20 shadow-2xl [&.open]:translate-x-0"
      >
        <header class="p-4 border-b border-base-content/5 flex items-center justify-between">
          <h3 class="font-bold flex items-center gap-2">
            <.icon name="hero-chat-bubble-left-right" class="size-5 opacity-50" />
            <span>Swarm Chat</span>
          </h3>

          <button
            class="btn btn-ghost btn-sm btn-circle"
            onclick="document.getElementById('chat-drawer').classList.remove('open')"
          >
            <.icon name="hero-x-mark" class="size-5" />
          </button>
        </header>

        <div class="flex-1 p-4 overflow-y-auto space-y-4">
          <div class="text-center py-8">
            <p class="text-xs opacity-50 italic">No active conversations.</p>
            <button class="btn btn-primary btn-sm mt-4">New Message</button>
          </div>
        </div>

        <footer class="p-4 border-t border-base-content/5">
          <div class="join w-full">
            <input
              class="input input-sm input-bordered join-item flex-1"
              placeholder="Type a message..."
            /> <button class="btn btn-sm btn-primary join-item px-4">Send</button>
          </div>
        </footer>
      </aside>
    </div>
    <.flash_group flash={@flash} />
    """
  end

  # ── Flash Messages ─────────────────────────────────────────
  @doc """
  Shows the flash group with standard titles and content.

  ## Examples

      <.flash_group flash={@flash} />
  """
  attr(:flash, :map, required: true, doc: "the map of flash messages")
  attr(:id, :string, default: "flash-group", doc: "the optional id of flash container")

  def flash_group(assigns) do
    ~H"""
    <div id={@id} aria-live="polite">
      <.flash kind={:info} flash={@flash} /> <.flash kind={:error} flash={@flash} />
      <.flash
        id="client-error"
        kind={:error}
        title="We can't find the internet"
        phx-disconnected={show(".phx-client-error #client-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#client-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        Attempting to reconnect
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>

      <.flash
        id="server-error"
        kind={:error}
        title="Something went wrong!"
        phx-disconnected={show(".phx-server-error #server-error") |> JS.remove_attribute("hidden")}
        phx-connected={hide("#server-error") |> JS.set_attribute({"hidden", ""})}
        hidden
      >
        Attempting to reconnect
        <.icon name="hero-arrow-path" class="ml-1 size-3 motion-safe:animate-spin" />
      </.flash>
    </div>
    """
  end

  # ── Theme Toggle ───────────────────────────────────────────
  @doc """
  Provides dark vs light theme toggle based on themes defined in app.css.
  """
  def theme_toggle(assigns) do
    ~H"""
    <div class="card relative flex flex-row items-center border-2 border-base-300 bg-base-300 rounded-full">
      <div class="absolute w-1/3 h-full rounded-full border-1 border-base-200 bg-base-100 brightness-200 left-0 [[data-theme=light]_&]:left-1/3 [[data-theme=dark]_&]:left-2/3 transition-[left]" />
      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="system"
      >
        <.icon name="hero-computer-desktop-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="light"
      >
        <.icon name="hero-sun-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
      <button
        class="flex p-2 cursor-pointer w-1/3"
        phx-click={JS.dispatch("phx:set-theme")}
        data-phx-theme="dark"
      >
        <.icon name="hero-moon-micro" class="size-4 opacity-75 hover:opacity-100" />
      </button>
    </div>
    """
  end

  defp active_path?(current_path, "/"), do: current_path == "/"

  defp active_path?(current_path, prefixes) when is_list(prefixes) do
    Enum.any?(prefixes, &active_path?(current_path, &1))
  end

  defp active_path?(current_path, prefix) when is_binary(current_path) do
    current_path == prefix or String.starts_with?(current_path, prefix <> "/")
  end

  defp active_path?(_current_path, _prefix), do: false

  defp page_heading(%{page_title: title}) when is_binary(title) and title != "", do: title

  defp page_heading(%{current_path: "/"}), do: "Dashboard"

  defp page_heading(%{current_path: path}) when path in ["/search"], do: "Swarm Search"

  defp page_heading(%{current_path: path}) when path in ["/personas", "/agents"],
    do: "Persona Directory"

  defp page_heading(%{current_path: path}) when is_binary(path) and path in ["/tools"],
    do: "Tool Directory"

  defp page_heading(%{current_path: path}) when is_binary(path) and path in ["/tools/internal"],
    do: "Internal Tools"

  defp page_heading(%{current_path: path}) when is_binary(path) and path in ["/feed"], do: "Feed"

  defp page_heading(%{current_path: path}) when is_binary(path) and path in ["/scenarios"],
    do: "Active Scenarios"

  defp page_heading(%{current_path: path}) when is_binary(path) and path in ["/governance"],
    do: "Governance & Wallet"

  defp page_heading(%{current_path: path})
       when is_binary(path) and path in ["/payment/dashboard"], do: "Payment Dashboard"

  defp page_heading(_assigns), do: "Swarm OS"
end
