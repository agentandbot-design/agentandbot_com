defmodule GovernanceCore.ProtocolCatalog do
  @moduledoc """
  Central protocol registry for AgentAndBot discovery surfaces.
  """

  @protocols [
    %{
      id: "mcp",
      name: "MCP",
      domain: "tool_access",
      purpose: "Standard tool, data, and prompt access for agents.",
      status: "supported",
      discovery_paths: ["/mcp", "/skills.json"],
      supported_by_runtimes: ["hermes", "agent_zero", "openclaw", "google_agent", "manus_style"]
    },
    %{
      id: "a2a",
      name: "A2A",
      domain: "agent_messaging",
      purpose: "Agent-to-agent discovery, delegation, and collaboration.",
      status: "supported",
      discovery_paths: ["/.well-known/agent.json", "/agents/{id}/.well-known/agent-card.json"],
      supported_by_runtimes: ["hermes", "openclaw", "google_agent"]
    },
    %{
      id: "acp",
      name: "ACP",
      domain: "agent_messaging",
      purpose: "REST-style multi-agent coordination and message envelopes.",
      status: "compatible_metadata",
      discovery_paths: ["/api/tasks/{id}/messages"],
      supported_by_runtimes: ["hermes", "google_agent"]
    },
    %{
      id: "anp",
      name: "ANP",
      domain: "agent_network",
      purpose: "Network discovery and agent capability announcement.",
      status: "compatible_metadata",
      discovery_paths: ["/api/protocols", "/api/agents/{id}/protocol-profile"],
      supported_by_runtimes: ["custom_webhook", "google_agent", "openclaw"]
    },
    %{
      id: "ucp",
      name: "UCP",
      domain: "commerce",
      purpose: "Catalog, intent, and commerce lifecycle metadata for agents.",
      status: "manifest_ready",
      discovery_paths: ["/api/agents/{id}/commerce", "/api/tasks/{id}/commerce-intent"],
      supported_by_runtimes: ["google_agent", "custom_webhook"]
    },
    %{
      id: "ap2",
      name: "AP2",
      domain: "payments",
      purpose: "Agent payment mandates, spending limits, and authorization metadata.",
      status: "manifest_ready",
      discovery_paths: ["/api/agents/{id}/commerce", "/api/v1/services/{slug}/verify"],
      supported_by_runtimes: ["google_agent", "hermes"]
    },
    %{
      id: "did",
      name: "DID",
      domain: "identity",
      purpose: "Public decentralized identifier metadata for agent identity.",
      status: "metadata_only",
      discovery_paths: ["/api/agents/{id}/identity"],
      supported_by_runtimes: ["custom_webhook", "google_agent", "agent_zero"]
    },
    %{
      id: "ed25519",
      name: "Ed25519",
      domain: "identity",
      purpose: "Public key type for agent identity verification metadata.",
      status: "metadata_only",
      discovery_paths: ["/api/agents/{id}/identity"],
      supported_by_runtimes: ["agent_zero", "custom_webhook"]
    },
    %{
      id: "openapi_3_1",
      name: "OpenAPI 3.1",
      domain: "api_contract",
      purpose: "HTTP API description for human and agent clients.",
      status: "supported",
      discovery_paths: ["/api/openapi.json"],
      supported_by_runtimes: [
        "hermes",
        "agent_zero",
        "openclaw",
        "google_agent",
        "custom_webhook",
        "manus_style",
        "space_agent",
        "minimax_agent"
      ]
    },
    %{
      id: "json_schema",
      name: "JSON Schema",
      domain: "api_contract",
      purpose: "Typed input and output contracts for skills and tools.",
      status: "supported",
      discovery_paths: ["/skills.json", "/api/openapi.json"],
      supported_by_runtimes: [
        "hermes",
        "agent_zero",
        "openclaw",
        "google_agent",
        "custom_webhook",
        "manus_style",
        "space_agent",
        "minimax_agent"
      ]
    },
    %{
      id: "x402",
      name: "x402",
      domain: "payments",
      purpose: "Payment challenge metadata and future machine-payable commerce.",
      status: "internal_credits_now",
      discovery_paths: ["/api/v1/services/{slug}/verify"],
      supported_by_runtimes: ["hermes", "openclaw", "manus_style", "custom_webhook"]
    }
  ]

  def protocols, do: @protocols

  def get(id) do
    Enum.find(@protocols, &(&1.id == id or &1.name == id))
  end

  def names, do: Enum.map(@protocols, & &1.name)

  def for_runtime(runtime_id) do
    Enum.filter(@protocols, &(runtime_id in &1.supported_by_runtimes))
  end
end
