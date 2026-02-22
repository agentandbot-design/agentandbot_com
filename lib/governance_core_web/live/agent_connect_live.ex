defmodule GovernanceCoreWeb.AgentConnectLive do
  use GovernanceCoreWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "agent/connect · ABL.ONE",
       handshake_state: :waiting,
       log_lines: [
         "[SYS] node=agentandbot.com proto=ABL.ONE/1.0",
         "[SYS] frame_size=8B crc=CRC32 encoding=Gibberlink"
       ]
     )}
  end

  @impl true
  def render(assigns) do
    ~H"""
    <style>
      *, *::before, *::after { box-sizing: border-box; }
      body { background: #0B0F14; margin: 0; }
      .entry-root {
        min-height: 100vh;
        display: grid;
        grid-template-rows: auto 1fr auto;
        background: #0B0F14;
        font-family: 'Inter', sans-serif;
        max-width: 760px;
        margin: 0 auto;
        padding: 0 40px;
      }
      .entry-nav {
        display: flex; align-items: center; justify-content: space-between;
        padding: 20px 0; border-bottom: 1px solid #1F2937;
      }
      .entry-logo { font-size: 13px; color: #9AA4B2; text-decoration: none; font-family: monospace; }
      .entry-proto { font-size: 11px; color: #3B82F6; font-family: monospace; letter-spacing: 0.5px; }

      .entry-main { padding: 48px 0 32px; }
      .entry-title {
        font-family: monospace; font-size: 13px; color: #9AA4B2;
        letter-spacing: 1px; text-transform: uppercase; margin: 0 0 24px;
      }

      .frame-box {
        background: #0B0F14; border: 1px solid #1F2937; border-radius: 8px;
        padding: 20px 24px; margin-bottom: 20px; font-family: monospace;
      }
      .frame-title { font-size: 10px; color: #3B82F6; letter-spacing: 1.5px; text-transform: uppercase; margin-bottom: 12px; }
      .frame-code { font-size: 13px; color: #E6EAF0; line-height: 1.7; }
      .frame-label { color: #64748B; }

      .log-box {
        border-left: 2px solid #1F2937; padding: 16px 20px;
        font-family: monospace; font-size: 12px; color: #64748B; line-height: 2;
        margin-bottom: 32px; background: #0A0D11; border-radius: 0 4px 4px 0;
      }
      .log-active { color: #9AA4B2; }

      .human-section {
        border-top: 1px solid #1F2937; padding-top: 32px; margin-top: 8px;
      }
      .human-label { font-size: 11px; color: #64748B; letter-spacing: 1px; text-transform: uppercase; font-family: monospace; margin-bottom: 16px; }
      .human-text { font-size: 14px; color: #9AA4B2; line-height: 1.6; margin-bottom: 20px; }
      .btn-connect {
        background: #3B82F6; color: #fff; font-size: 13px; font-weight: 500;
        padding: 10px 20px; border-radius: 8px; border: none; cursor: pointer;
        font-family: 'Inter', sans-serif; transition: background 0.15s; text-decoration: none;
        display: inline-block;
      }
      .btn-connect:hover { background: #2563EB; }
      .btn-ghost-sm {
        font-size: 12px; color: #9AA4B2; text-decoration: none; margin-left: 16px;
      }

      .entry-footer {
        border-top: 1px solid #1F2937; padding: 16px 0;
        display: flex; justify-content: space-between; font-size: 11px;
        color: #64748B; font-family: monospace;
      }
    </style>

    <div class="entry-root">
      <%!-- NAV --%>
      <nav class="entry-nav">
        <a href="/" class="entry-logo">agentandbot</a>
        <span class="entry-proto">ABL.ONE/1.0 · HANDSHAKE</span>
      </nav>

      <%!-- MAIN --%>
      <main class="entry-main">
        <p class="entry-title">// agent entry point</p>

        <%!-- FRAME SPEC --%>
        <div class="frame-box">
          <div class="frame-title">Frame Structure</div>
          <div class="frame-code">
            <span class="frame-label">[FROM:1]</span> [TO:1] [OP:1] [ARG:1] [CRC32:4]<br/>
            <span class="frame-label">encoding</span> Gibberlink · 8 byte · binary<br/>
            <span class="frame-label">auth    </span> OAuth 2.1 M2M · JIT token
          </div>
        </div>

        <%!-- LIVE LOG --%>
        <div class="log-box">
          <%= for {line, i} <- Enum.with_index(@log_lines) do %>
            <div class={if i == length(@log_lines) - 1, do: "log-active"}><%= line %></div>
          <% end %>
          <div style="color: #3B82F6;">█</div>
        </div>

        <%!-- HUMAN SECTION --%>
        <div class="human-section">
          <div class="human-label">// for humans</div>
          <p class="human-text">
            This is the machine-to-machine entry point for agentandbot.com agents.<br/>
            If you are a developer or operator, connect your agent below.
          </p>
          <a href="/.well-known/agent.json" class="btn-connect">View agent.json →</a>
          <a href="/" class="btn-ghost-sm">Back to homepage</a>
        </div>
      </main>

      <%!-- FOOTER --%>
      <footer class="entry-footer">
        <span>node · agentandbot.com</span>
        <span>CRC32 · verified</span>
        <span>UMP v1.2</span>
      </footer>
    </div>
    """
  end
end
