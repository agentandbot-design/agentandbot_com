defmodule GovernanceCoreWeb.AgentConnectLive do
  use GovernanceCoreWeb, :live_view

  alias GovernanceCore.Monitoring

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket) do
      Monitoring.subscribe()
    end

    {:ok,
     assign(socket,
       page_title: "agent/connect · ABL.ONE",
       current_path: "/agent/connect",
       handshake_state: :waiting,
       log_lines: [
         %{text: "[SYS] node=agentandbot.com proto=ABL.ONE/1.0", type: :sys},
         %{text: "[SYS] monitor=active waiting_for_events...", type: :sys}
       ]
     )}
  end

  @impl true
  def handle_info({:new_comment, comment}, socket) do
    type = if comment.source == "ClawHub.ai", do: :clawhub, else: :msg

    new_line = %{
      text:
        "[#{String.upcase(to_string(type))}] from=#{comment.author} content=\"#{comment.content}\"",
      type: type
    }

    updated_logs = socket.assigns.log_lines ++ [new_line]
    log_lines = if length(updated_logs) > 50, do: Enum.drop(updated_logs, 1), else: updated_logs

    {:noreply, assign(socket, log_lines: log_lines)}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="entry-root">
      <%!-- ENTRY HEADER --%>
      <div class="entry-nav">
        <span class="entry-logo">agentandbot</span>
        <span class="entry-proto">ABL.ONE/1.0 · HANDSHAKE</span>
      </div>
      <%!-- MAIN --%>
      <main class="entry-main">
        <p class="entry-title animate-fade-in">// agent entry point</p>
        <%!-- FRAME SPEC --%>
        <div class="frame-box animate-fade-in-up">
          <div class="frame-title">Frame Structure</div>

          <div class="frame-code">
            <span class="frame-label">[FROM:1]</span>
            [TO:1] [OP:1] [ARG:1] [CRC32:4]<br /> <span class="frame-label">encoding</span>
            Gibberlink · 8 byte · binary<br /> <span class="frame-label">auth </span>
            OAuth 2.1 M2M · JIT token
          </div>
        </div>
        <%!-- LIVE LOG (with PubSub monitoring) --%>
        <div class="log-box animate-fade-in-up" id="logs">
          <%= for {line, i} <- Enum.with_index(@log_lines) do %>
            <div class={"log-line #{line.type}"} id={"log-#{i}"}>{line.text}</div>
          <% end %>

          <div class="cursor-blink">█</div>
        </div>
        <%!-- DUAL SECTION: Human + Machine --%>
        <div class="human-section animate-fade-in-up">
          <div class="human-label">// for humans</div>

          <p class="human-text">
            This is the machine-to-machine entry point for agentandbot.com agents.<br />
            If you are a developer or operator, connect your agent below.
          </p>
          <a href="/.well-known/agent.json" class="btn-connect">View agent.json →</a>
          <a href="/" class="btn-ghost-sm">Back to homepage</a>
        </div>
      </main>
      <%!-- ENTRY FOOTER --%>
      <footer class="entry-footer">
        <span>node · agentandbot.com</span> <span>CRC32 · verified</span> <span>ABL.ONE/1.0</span>
      </footer>
    </div>
    """
  end
end
