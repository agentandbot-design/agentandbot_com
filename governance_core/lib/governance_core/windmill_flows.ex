defmodule GovernanceCore.WindmillFlows do
  @moduledoc """
  Safe catalog of workflows that should be orchestrated through Windmill.

  This module intentionally exposes only metadata. Windmill MCP tokens and
  service credentials must stay in vault/env configuration.
  """

  @workspace "admins"
  @base_url "https://windmill.e-any.online/"
  @mcp_path "/api/mcp/w/admins/mcp"

  @flows [
    %{
      id: "feed-ingestion",
      name: "Feed Ingestion",
      status: "ready_to_build",
      priority: "high",
      owner: "content_ops",
      trigger: "scheduled_or_manual",
      agent_scopes: ["workflow:run", "feed:write"],
      inputs: ["source_url", "source_type", "author_type", "tags"],
      outputs: ["draft_feed_posts", "import_report"],
      recommended_for: [
        "RSS and Atom imports",
        "awesome-llm-apps daily picks",
        "future social-source normalization"
      ],
      notes: "Keep moderation/publish approval in AgentAndBot; Windmill should import drafts."
    },
    %{
      id: "cv-generator-render",
      name: "CV Generator Render Pipeline",
      status: "ready_to_build",
      priority: "high",
      owner: "product",
      trigger: "api_or_queue",
      agent_scopes: ["workflow:run", "cv:create"],
      inputs: ["profile", "template", "locale", "export_format"],
      outputs: ["artifact_url", "artifact_hash", "render_log"],
      recommended_for: [
        "PDF/DOCX rendering",
        "template fan-out",
        "long-running CV exports"
      ],
      notes:
        "AgentAndBot gateway should keep payment validation; Windmill can handle render jobs."
    },
    %{
      id: "kadro-task-runtime",
      name: "KADRO Task Runtime",
      status: "candidate",
      priority: "high",
      owner: "marketplace_ops",
      trigger: "webhook",
      agent_scopes: ["workflow:run", "task:execute", "job:read"],
      inputs: ["task_id", "agent_id", "instructions", "callback_url"],
      outputs: ["task_events", "artifact", "runtime_status"],
      recommended_for: [
        "real task execution adapter",
        "agent log streaming",
        "human approval checkpoints"
      ],
      notes: "Keep the existing KADRO simulation as demo mode while Windmill executes real jobs."
    },
    %{
      id: "internal-tool-health",
      name: "Internal Tool Health Polling",
      status: "ready_to_build",
      priority: "medium",
      owner: "internal_ops",
      trigger: "scheduled",
      agent_scopes: ["workflow:run", "job:read", "tools:read"],
      inputs: ["tool_slug", "health_url"],
      outputs: ["health_status", "latency_ms", "incident_hint"],
      recommended_for: [
        "Uptime checks",
        "Nginx routed service smoke tests",
        "internal tool registry refresh"
      ],
      notes: "Prefer read-only checks; do not pass admin credentials to generic health flows."
    },
    %{
      id: "brain-sync-backup",
      name: "Brain Sync Backup",
      status: "candidate",
      priority: "medium",
      owner: "agent_ops",
      trigger: "scheduled_or_manual",
      agent_scopes: ["workflow:run", "agent:dna:read"],
      inputs: ["agent_id", "destination_ref"],
      outputs: ["dna_export_hash", "backup_status"],
      recommended_for: [
        "agent DNA export snapshots",
        "portable backup verification",
        "pre-deployment sync jobs"
      ],
      notes: "Never include private identity material or provider secrets in DNA backups."
    }
  ]

  def windmill_card do
    %{
      slug: "windmill",
      name: "Windmill",
      base_url: @base_url,
      workspace: @workspace,
      mcp_path: @mcp_path,
      token_policy: "vault_or_env_only",
      token_location: "Stored in vault or runtime environment; never returned by API.",
      flows: list_flows()
    }
  end

  def list_flows, do: @flows

  def get_flow(id), do: Enum.find(@flows, &(&1.id == id))
end
