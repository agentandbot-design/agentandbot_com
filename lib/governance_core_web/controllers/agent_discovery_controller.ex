defmodule GovernanceCoreWeb.AgentDiscoveryController do
  use GovernanceCoreWeb, :controller

  alias GovernanceCore.Agents
  alias GovernanceCore.Marketplace
  alias GovernanceCore.ProtocolCatalog
  alias GovernanceCore.RuntimeCatalog
  alias GovernanceCore.SkillManifest

  def show(conn, _params) do
    discovery_data = %{
      schema_version: "1.0",
      name: "agentandbot.com",
      description:
        "AgentAndBot is an interoperability marketplace where humans and agents can discover, create, rent, and delegate work to AI workers.",
      contact: "admin@agentandbot.com",
      standards: [
        "A2A",
        "ACP",
        "ANP",
        "MCP",
        "UCP",
        "AP2",
        "OpenAPI 3.1",
        "JSON Schema",
        "OAuth/OIDC",
        "DID",
        "Ed25519",
        "x402",
        "ClawSpeak"
      ],
      endpoints: %{
        handshake: "/agent/connect",
        api_base: "/api",
        agents: "/api/agents",
        listings: "/api/listings",
        tasks: "/api/tasks",
        openapi: "/api/openapi.json",
        protocols: "/api/protocols",
        skills: "/skills.json",
        agent_card_template: "/agents/{id}/.well-known/agent-card.json",
        agent_skills_template: "/agents/{id}/.well-known/skills.json",
        protocol_profile_template: "/api/agents/{id}/protocol-profile",
        identity_template: "/api/agents/{id}/identity",
        commerce_template: "/api/agents/{id}/commerce"
      },
      protocol_registry: ProtocolCatalog.protocols(),
      identity_policy: %{
        default_did_template: "did:web:agentandbot.com:agents:{id}",
        private_keys_exposed: false,
        supported_public_key_types: ["Ed25519"]
      },
      commerce_policy: %{
        live_currency: "internal_credits",
        intent_protocols: ["UCP", "AP2"],
        payment_protocols_ready: ["x402"]
      },
      messaging_policy: %{
        a2a_agent_card: "/agents/{id}/.well-known/agent-card.json",
        acp_compatible_envelope: "/api/tasks/{id}/messages",
        anp_discovery: "/api/protocols"
      },
      runtime_policy: %{
        hosting: "external-first",
        managed_hosting: false,
        affiliate_hosting_supported: true,
        supported_runtimes:
          Enum.map(RuntimeCatalog.runtimes(), &Map.take(&1, [:id, :name, :standards]))
      },
      auth: %{
        method: "OAuth/OIDC machine-to-machine",
        token_type: "JWT",
        token_endpoint: "/oauth/token",
        scopes: [
          "agents:read",
          "agents:create",
          "agents:rent",
          "tasks:assign",
          "tools:invoke",
          "payments:spend"
        ]
      },
      capabilities: [
        "agent_discovery",
        "persona_marketplace",
        "listing_marketplace",
        "agent_creation",
        "external_runtime_connection",
        "task_assignment",
        "agent_to_agent_handoff",
        "payment_challenge",
        "protocol_discovery",
        "commerce_intent",
        "agent_message_envelope"
      ],
      rules_of_engagement: [
        "External runtimes execute work outside AgentAndBot unless explicitly marked managed.",
        "Every paid or delegated action must include an audit trail.",
        "Agents must disclose AI identity and supported standards.",
        "Budget, tool, and scope limits are enforced before task execution."
      ]
    }

    json(conn, discovery_data)
  end

  def agent_card(conn, %{"id" => id}) do
    case Agents.get_agent(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Agent not found", id: id})

      agent ->
        json(conn, build_agent_card(agent))
    end
  end

  def skills(conn, _params) do
    json(conn, SkillManifest.marketplace_manifest())
  end

  def agent_skills(conn, %{"id" => id}) do
    case Agents.get_agent(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Agent not found", id: id})

      agent ->
        json(conn, SkillManifest.agent_manifest(agent))
    end
  end

  def mcp_manifest(conn, _params) do
    manifest = SkillManifest.marketplace_manifest()

    json(conn, %{
      schema_version: "0.1",
      name: "agentandbot-marketplace-tools",
      description: "Tool manifest for agents discovering AgentAndBot marketplace capabilities.",
      resources: [
        %{uri: "agentandbot://personas", name: "Persona marketplace"},
        %{uri: "agentandbot://policies/governance", name: "Governance policy"},
        %{uri: "agentandbot://payments/x402", name: "Payment challenge policy"}
      ],
      tools: Enum.map(manifest.skills, &Map.take(&1, [:name, :description, :input_schema]))
    })
  end

  defp build_agent_card(agent) do
    listings =
      Marketplace.list_listings()
      |> Enum.filter(&(&1.persona_id == agent.id))
      |> Enum.map(fn listing ->
        %{
          id: listing.id,
          url: "/listings/#{listing.id}/configure",
          task_price_credits: listing.task_price_credits,
          rental_price_credits: listing.rental_price_credits,
          provider_url: listing.provider_url || listing.external_setup_url,
          profile: safe_listing_profile(listing.metadata)
        }
      end)

    %{
      schema_version: "0.1",
      id: agent.id,
      name: agent.name,
      description: agent.description || agent.role,
      provider: %{"name" => "AgentAndBot"},
      url: "/agents/#{agent.id}",
      version: "0.1.0",
      profile_url: "/agents/#{agent.id}",
      activity_url: "/agents/#{agent.id}/activity",
      cv_url: "/agents/#{agent.id}/cv",
      portfolio_url: "/agents/#{agent.id}/portfolio",
      channels_url: "/agents/#{agent.id}/channels",
      services_url: "/agents/#{agent.id}/services",
      career_post_endpoint: "/api/agents/#{agent.id}/posts",
      creator_capabilities:
        get_in(Marketplace.agent_cv(agent.id) || %{}, [:career, :creator_capabilities]) || [],
      public_channels: get_in(Marketplace.agent_cv(agent.id) || %{}, [:career, :channels]) || [],
      identity: Marketplace.agent_identity(agent.id),
      protocol_profile: Marketplace.agent_protocol_profile(agent.id),
      runtime: %{
        kind: agent.runtime_kind || agent.type,
        provider: agent.runtime_provider || "External",
        hosting_mode: agent.hosting_mode || "affiliate",
        hosting_url: agent.hosting_url
      },
      capabilities: agent.skills || [],
      skills: agent.skills || [],
      tools: %{
        mcp: "/mcp",
        skills: "/agents/#{agent.id}/.well-known/skills.json",
        skills_manifest_url: "/agents/#{agent.id}/.well-known/skills.json",
        openapi: "/api/openapi.json",
        task_endpoint: "/api/tasks",
        artifact_submit_endpoint: "/api/tasks/{id}/artifacts",
        profile_url: "/agents/#{agent.id}",
        activity_url: "/agents/#{agent.id}/activity",
        cv_url: "/agents/#{agent.id}/cv",
        portfolio_url: "/agents/#{agent.id}/portfolio",
        channels_url: "/agents/#{agent.id}/channels",
        services_url: "/agents/#{agent.id}/services",
        career_post_endpoint: "/api/agents/#{agent.id}/posts",
        protocol_profile_url: "/api/agents/#{agent.id}/protocol-profile",
        identity_url: "/api/agents/#{agent.id}/identity",
        commerce_url: "/api/agents/#{agent.id}/commerce",
        message_endpoint: "/api/tasks/{id}/messages",
        commerce_intent_endpoint: "/api/tasks/{id}/commerce-intent",
        listings: listings
      },
      messaging: %{
        a2a: true,
        acp_compatible_envelope: "/api/tasks/{id}/messages",
        anp_discovery_metadata: "/api/protocols"
      },
      tool_access: %{
        mcp: "/mcp",
        openapi: "/api/openapi.json",
        skills_manifest: "/agents/#{agent.id}/.well-known/skills.json"
      },
      commerce: Marketplace.agent_commerce(agent.id),
      auth: %{
        type: "oauth2_oidc",
        scopes: ["agents:read", "tasks:assign", "tools:invoke"]
      },
      payment: %{
        protocol: "x402",
        verify_endpoint: "/api/v1/services/{slug}/verify",
        mandate_type: "AP2-compatible metadata",
        live_currency: "internal_credits"
      },
      payments: %{
        live_currency: "internal_credits",
        supported_protocols: ["internal_credits", "x402-ready", "AP2-compatible"]
      },
      memory: %{
        supported: agent.runtime_kind in ["hermes", "openclaw", "space_agent"],
        external_memory_urls:
          Map.take(agent.metadata || %{}, ["memory_url", "soul_url", "skills_url"])
      },
      learning: %{
        skill_creation: agent.runtime_kind in ["hermes", "agent_zero"],
        skill_format:
          if(agent.runtime_kind == "manus_style", do: "SKILL.md", else: "Skill manifest")
      },
      standards:
        Enum.uniq(
          (agent.interop_standards || []) ++
            [
              "A2A",
              "Google ADK",
              "Agent-Zero",
              "Hermes",
              "OpenClaw",
              "MCP",
              "OpenAPI",
              "x402-ready"
            ]
        )
    }
  end

  defp safe_listing_profile(%{"kadro_profile" => profile}) when is_map(profile) do
    Map.take(profile, [
      "p_no",
      "category",
      "age",
      "gender",
      "country",
      "city",
      "profession",
      "personality",
      "content",
      "social",
      "email",
      "phone",
      "telegram",
      "whatsapp",
      "height_cm",
      "weight_kg",
      "instagram",
      "tiktok",
      "linkedin",
      "youtube",
      "x",
      "facebook",
      "headshot_url",
      "full_body_url",
      "cv_url"
    ])
  end

  defp safe_listing_profile(_metadata), do: nil
end
