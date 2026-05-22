defmodule GovernanceCore.RuntimeCatalog do
  @moduledoc """
  Supported agent runtime and external hosting options for the marketplace.

  AgentAndBot starts as an interoperability and marketplace layer. Runtime
  execution is delegated to external providers or user-managed endpoints.
  """

  @runtimes [
    %{
      id: "hermes",
      name: "Hermes",
      description:
        "Persistent personal or business agent with memory, messaging channels, and reusable skill creation.",
      source_url: "https://hermes-agent.org/",
      capability_tags: [
        "persistent_memory",
        "skill_creation",
        "messaging_channels",
        "self_hosted",
        "soul_md",
        "memory_md",
        "markdown_skills"
      ],
      standards: [
        "A2A",
        "ACP",
        "MCP",
        "SOUL.md",
        "MEMORY.md",
        "USER.md",
        "Markdown Skills",
        "OpenAPI 3.1",
        "JSON Schema",
        "x402-ready"
      ],
      default_skills: [
        "remember_context",
        "create_reusable_skill",
        "delegate_task",
        "deliver_artifact"
      ],
      hosting_options: ["self_hosted", "hostinger", "custom_partner"]
    },
    %{
      id: "agent_zero",
      name: "Agent-Zero",
      description:
        "Autonomous computer assistant for tool-heavy workflows, plugins, transparent execution, and local/Docker control.",
      source_url: "https://www.agent-zero.ai/",
      capability_tags: [
        "tool_creation",
        "plugin_hub",
        "computer_use",
        "docker",
        "local_connector",
        "ed25519_identity",
        "dynamic_tools"
      ],
      standards: [
        "Ed25519",
        "identity.json",
        "dynamic_tools",
        "plugins",
        "MCP-compatible",
        "OpenAPI 3.1",
        "JSON Schema"
      ],
      default_skills: ["use_computer", "create_tool", "install_plugin", "run_research"],
      hosting_options: ["self_hosted", "hostinger", "custom_partner"]
    },
    %{
      id: "openclaw",
      name: "OpenClaw / Clawbot",
      description:
        "Local-first, chat-native agent runtime with workspace files, memory, tool notes, skills, and channel integrations.",
      source_url: "https://docs.openclaw.ai/agent",
      capability_tags: [
        "local_first",
        "workspace_runtime",
        "channel_integrations",
        "skills",
        "memory"
      ],
      standards: [
        "A2A",
        "A2A v0.3.0",
        "workspace_gateway",
        "channel_gateway",
        "ClawSpeak",
        "ABL.ONE",
        "MCP",
        "x402-ready"
      ],
      default_skills: ["read_workspace_bootstrap", "invoke_skill", "handoff_task", "use_channel"],
      hosting_options: ["self_hosted", "hostinger", "custom_partner"]
    },
    %{
      id: "google_agent",
      name: "Google ADK Agent",
      description:
        "Code-first production agent built with ADK-style tools, orchestration, evaluation, and cloud deployment options.",
      source_url: "https://adk.dev/",
      capability_tags: [
        "code_first",
        "multi_agent",
        "tool_calling",
        "evaluation",
        "vertex_agent_engine"
      ],
      standards: ["A2A", "MCP", "UCP", "AP2", "OpenAPI 3.1", "OAuth/OIDC"],
      default_skills: [
        "call_adk_tool",
        "orchestrate_subagents",
        "evaluate_run",
        "deploy_external"
      ],
      hosting_options: ["self_hosted", "custom_partner"]
    },
    %{
      id: "custom_webhook",
      name: "Custom Webhook",
      description: "Bring an existing hosted agent by exposing a task endpoint.",
      source_url: nil,
      capability_tags: ["bring_your_own_agent", "webhook", "openapi"],
      standards: ["OpenAPI 3.1", "JSON Schema", "OAuth/OIDC", "DID optional"],
      default_skills: ["receive_task", "return_artifact", "report_status"],
      hosting_options: ["self_hosted", "custom_partner"]
    },
    %{
      id: "manus_style",
      name: "Manus-style Delivery Agent",
      description:
        "Work-delivery agent pattern focused on browser/file execution, editable artifacts, and real-time task progress.",
      source_url: "https://manus.im/tr/tools",
      capability_tags: ["artifact_delivery", "browser_use", "filesystem", "realtime_progress"],
      standards: [
        "SKILL.md",
        "MCP",
        "sandboxed_tools",
        "artifact_delivery",
        "OpenAPI 3.1",
        "JSON Schema",
        "x402-ready"
      ],
      default_skills: [
        "create_presentation",
        "create_document",
        "create_spreadsheet",
        "create_website"
      ],
      hosting_options: ["self_hosted", "hostinger", "custom_partner"]
    },
    %{
      id: "space_agent",
      name: "Space Agent",
      description:
        "Workspace-shaping agent pattern for project spaces, files, and persistent collaboration context.",
      source_url: "https://github.com/agent0ai/space-agent",
      capability_tags: ["workspace", "project_space", "collaboration_context"],
      standards: ["MCP", "OpenAPI 3.1", "JSON Schema"],
      default_skills: ["shape_workspace", "read_project_context", "organize_artifacts"],
      hosting_options: ["self_hosted", "hostinger", "custom_partner"]
    },
    %{
      id: "minimax_agent",
      name: "MiniMax-style Gallery Agent",
      description:
        "Gallery/template driven agent pattern for fast, task-specific creative and productivity agents.",
      source_url: "https://agent.minimax.io/gallery",
      capability_tags: ["gallery_template", "creative_tools", "quick_start"],
      standards: ["MCP", "OpenAPI 3.1", "JSON Schema"],
      default_skills: ["instantiate_template", "generate_media", "deliver_artifact"],
      hosting_options: ["self_hosted", "custom_partner"]
    }
  ]

  @hosting_providers [
    %{
      id: "hostinger",
      name: "Hostinger",
      mode: "affiliate",
      url: "https://www.hostinger.com/",
      description: "External hosting partner option for user-managed deployments."
    },
    %{
      id: "self_hosted",
      name: "Self-hosted",
      mode: "external",
      url: nil,
      description: "User provides their own server, webhook, or runtime endpoint."
    },
    %{
      id: "custom_partner",
      name: "Custom partner",
      mode: "affiliate",
      url: nil,
      description: "Placeholder for future affiliate hosting partners."
    }
  ]

  def runtimes, do: @runtimes
  def hosting_providers, do: @hosting_providers

  def get_runtime(id) do
    Enum.find(@runtimes, custom_webhook(), &(&1.id == id))
  end

  def get_hosting_provider(id) do
    Enum.find(@hosting_providers, List.first(@hosting_providers), &(&1.id == id))
  end

  defp custom_webhook do
    Enum.find(@runtimes, &(&1.id == "custom_webhook"))
  end
end
