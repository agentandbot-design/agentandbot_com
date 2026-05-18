defmodule GovernanceCoreWeb.Api.AgentController do
  use GovernanceCoreWeb, :controller

  alias GovernanceCore.Agents
  alias GovernanceCore.Marketplace
  alias GovernanceCore.RuntimeCatalog

  def index(conn, _params) do
    agents = Agents.list_agents()

    json(conn, %{
      data: Enum.map(agents, &agent_payload/1),
      meta: %{
        total: length(agents),
        standards: [
          "A2A",
          "MCP",
          "ACP",
          "ANP",
          "UCP",
          "AP2",
          "DID",
          "OpenAPI 3.1",
          "JSON Schema",
          "OAuth/OIDC",
          "x402"
        ],
        api_version: "v1"
      }
    })
  end

  def show(conn, %{"id" => id}) do
    case Agents.get_agent(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Agent not found", id: id})

      agent ->
        json(conn, %{data: agent_payload(agent)})
    end
  end

  def cv(conn, %{"id" => id}) do
    case Marketplace.agent_cv(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Agent not found", id: id})

      cv ->
        json(conn, %{data: cv})
    end
  end

  def portfolio(conn, %{"id" => id}) do
    case Marketplace.agent_portfolio(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Agent not found", id: id})

      portfolio ->
        json(conn, %{data: portfolio})
    end
  end

  def activity(conn, %{"id" => id}) do
    case Marketplace.agent_activity(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Agent not found", id: id})

      activity ->
        json(conn, %{data: activity})
    end
  end

  def channels(conn, %{"id" => id}) do
    case Marketplace.agent_channels(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Agent not found", id: id})

      channels ->
        json(conn, %{data: channels})
    end
  end

  def services(conn, %{"id" => id}) do
    case Marketplace.agent_services(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Agent not found", id: id})

      services ->
        json(conn, %{data: services})
    end
  end

  def create_post(conn, %{"id" => id} = params) do
    params =
      Map.drop(params, ["id", "author_type", "author_id", "author_name", "status", "post_type"])

    case Marketplace.create_agent_career_post(id, params) do
      {:ok, post} ->
        conn
        |> put_status(:created)
        |> json(%{
          data: GovernanceCore.Feed.post_payload(post),
          message: "Agent career post saved as draft"
        })

      {:error, :agent_not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Agent not found", id: id})

      {:error, _changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Validation failed", details: "Check required fields"})
    end
  end

  def protocol_profile(conn, %{"id" => id}) do
    case Marketplace.agent_protocol_profile(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Agent not found", id: id})

      profile ->
        json(conn, %{data: profile})
    end
  end

  def identity(conn, %{"id" => id}) do
    case Marketplace.agent_identity(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Agent not found", id: id})

      identity ->
        json(conn, %{data: identity})
    end
  end

  def commerce(conn, %{"id" => id}) do
    case Marketplace.agent_commerce(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Agent not found", id: id})

      commerce ->
        json(conn, %{data: commerce})
    end
  end

  def create(conn, %{"name" => _name, "category" => _category} = params) do
    case Agents.create_agent(params) do
      {:ok, agent} ->
        runtime = RuntimeCatalog.get_runtime(agent.runtime_kind || agent.type || "custom_webhook")

        Marketplace.upsert_policy(%{
          persona_id: agent.id,
          allowed_scopes:
            get_in(params, ["policy", "allowed_scopes"]) ||
              [
                "agents:read",
                "tasks:assign",
                "tools:invoke"
              ],
          allowed_skills: get_in(params, ["policy", "allowed_skills"]) || runtime.default_skills,
          max_budget_credits: get_in(params, ["policy", "max_budget_credits"]),
          external_endpoint:
            get_in(params, ["policy", "external_endpoint"]) ||
              get_in(params, ["metadata", "external_endpoint"])
        })

        conn
        |> put_status(:created)
        |> json(%{
          data: agent_payload(agent),
          message: "Agent registered for external runtime connection"
        })

      {:error, _changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Validation failed", details: "Check required fields"})
    end
  end

  def create(conn, _params) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: "Missing required fields: name, category"})
  end

  defp agent_payload(agent) do
    %{
      id: agent.id,
      name: agent.name,
      role: agent.role,
      category: agent.category,
      description: agent.description,
      status: agent.status,
      trust_score: agent.trust_score,
      runtime: %{
        kind: agent.runtime_kind || agent.type,
        provider: agent.runtime_provider || "External",
        hosting_mode: agent.hosting_mode || "affiliate",
        hosting_url: agent.hosting_url
      },
      interop: %{
        protocol: agent.protocol,
        standards: agent.interop_standards || [],
        agent_card_url: agent.agent_card_url || "/agents/#{agent.id}/.well-known/agent-card.json",
        skill_manifest_url: "/agents/#{agent.id}/.well-known/skills.json",
        cv_url: "/agents/#{agent.id}/cv",
        portfolio_url: "/agents/#{agent.id}/portfolio",
        activity_url: "/agents/#{agent.id}/activity",
        channels_url: "/agents/#{agent.id}/channels",
        services_url: "/agents/#{agent.id}/services",
        career_post_url: "/agents/#{agent.id}/posts/new",
        protocol_profile_url: "/api/agents/#{agent.id}/protocol-profile",
        identity_url: "/api/agents/#{agent.id}/identity",
        commerce_url: "/api/agents/#{agent.id}/commerce"
      },
      career: (Marketplace.agent_cv(agent.id) || %{})[:career],
      skills: agent.skills || [],
      price_monthly: agent.price_monthly,
      owner: agent.owner
    }
  end
end
