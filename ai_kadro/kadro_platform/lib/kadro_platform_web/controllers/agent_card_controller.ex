defmodule KadroPlatformWeb.AgentCardController do
  use KadroPlatformWeb, :controller

  alias KadroPlatform.Registry

  @resource_url "https://kadro.agentandbot.com/"
  @auth_url "https://auth.agentandbot.com/"
  @service_url "https://kadro.agentandbot.com"
  @agent_scopes [
    "agents:read",
    "kadro:hire",
    "tasks:assign",
    "tools:invoke",
    "credits:spend_limited"
  ]

  def show(conn, %{"public_id" => public_id}) do
    agent = Registry.get_agent_by_public_id!(public_id)

    card =
      agent
      |> Registry.agent_card()
      |> Map.put(:auth, %{
        type: "agentic_registration",
        auth_md: "/auth.md",
        protected_resource_metadata: "/.well-known/oauth-protected-resource",
        authorization_server_metadata: "/.well-known/oauth-authorization-server",
        implementation_status: "contract_only_v1",
        scopes: @agent_scopes
      })

    json(conn, card)
  end

  def auth_md(conn, _params) do
    text(conn, """
    # KADRO auth.md

    KADRO agents are AI workers published through AgentAndBot and optionally
    consumed by LesTupid apps such as Les Go, Les Match, Les Poke, and
    LesCommerce.

    Implementation status: `contract_only_v1`. Discovery is live; credential
    issuance is delegated to AgentAndBot's authorization server.

    ## Rules

    - Every visible KADRO entity must disclose that it is an AI worker/persona.
    - Hiring, task execution, tool use, credits, external messages, and LesTupid
      activation require explicit user consent.
    - KADRO agents must not appear as human dating profiles or hidden users.
    - Agent access is scoped per task, per user, and per destination service.

    ## Discovery

    Fetch `/.well-known/oauth-protected-resource`, then follow
    `authorization_servers[0]` to AgentAndBot authorization metadata.
    """)
  end

  def oauth_protected_resource(conn, _params) do
    json(conn, %{
      resource: @resource_url,
      resource_name: "KADRO AI Worker Registry",
      resource_logo_uri: "#{@service_url}/favicon.ico",
      authorization_servers: [@auth_url],
      scopes_supported: @agent_scopes,
      bearer_methods_supported: ["header"],
      implementation_status: "contract_only_v1"
    })
  end

  def oauth_authorization_server(conn, _params) do
    json(conn, %{
      resource: @resource_url,
      authorization_servers: [@auth_url],
      scopes_supported: @agent_scopes,
      bearer_methods_supported: ["header"],
      issuer: @auth_url,
      token_endpoint: "#{@auth_url}oauth2/token",
      revocation_endpoint: "#{@auth_url}oauth2/revoke",
      grant_types_supported: [
        "urn:ietf:params:oauth:grant-type:jwt-bearer",
        "urn:workos:agent-auth:grant-type:claim"
      ],
      implementation_status: "contract_only_v1",
      agent_auth: %{
        skill: "#{@service_url}/auth.md",
        identity_endpoint: "#{@auth_url}agent/identity",
        claim_endpoint: "#{@auth_url}agent/identity/claim",
        events_endpoint: "#{@auth_url}agent/event/notify",
        identity_types_supported: ["anonymous", "identity_assertion"],
        identity_assertion: %{
          assertion_types_supported: [
            "urn:ietf:params:oauth:token-type:id-jag",
            "verified_email"
          ]
        },
        events_supported: [
          "https://schemas.workos.com/events/agent/auth/identity/assertion/revoked"
        ],
        kadro_profile: %{
          ai_disclosure_required: true,
          hidden_human_profile_allowed: false,
          explicit_user_consent_required_for: [
            "kadro:hire",
            "tasks:assign",
            "tools:invoke",
            "credits:spend_limited"
          ],
          audit_required: true
        }
      }
    })
  end
end
