defmodule GovernanceCoreWeb.Api.AgentController do
  use GovernanceCoreWeb, :controller

  alias GovernanceCore.Agents
  alias GovernanceCore.AgentImages
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

  def generate_image(conn, %{"id" => id} = params) do
    actor =
      get_req_header(conn, "x-agentandbot-user")
      |> List.first()
      |> Kernel.||(Map.get(params, "actor"))

    params = Map.put(params, "actor", actor)

    case AgentImages.generate_agent_image(id, params) do
      {:ok, payload} ->
        json(conn, %{data: payload, message: "Agent image generated"})

      {:error, :unauthorized} ->
        conn
        |> put_status(:forbidden)
        |> json(%{error: "User is not allowed to generate agent images"})

      {:error, :missing_gemini_api_key} ->
        conn
        |> put_status(:payment_required)
        |> json(%{error: "GEMINI_API_KEY is not configured"})

      {:error, :missing_prompt} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Missing prompt"})

      {:error, :invalid_image_kind} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "image_kind must be headshot or full_body"})

      {:error, {:gemini_quota_exceeded, _body}} ->
        conn
        |> put_status(:too_many_requests)
        |> json(%{
          error:
            "Gemini quota or rate limit was reached. Try again later or use provider_api_key with another Gemini key."
        })

      {:error, :agent_not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Agent not found", id: id})

      {:error, reason} ->
        conn
        |> put_status(:bad_gateway)
        |> json(%{error: "Gemini image generation failed", details: inspect(reason)})
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

  def export_dna(conn, %{"id" => id}) do
    case Agents.get_agent(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Agent not found", id: id})

      agent ->
        # Get KADRO profile
        kadro_profile = Map.get(agent.metadata || %{}, "kadro_profile", %{})

        # Build the DNA payload
        dna = %{
          "level" => agent.level || 1,
          "xp" => agent.xp || 0,
          "achievements" => agent.achievements || [],
          "memory_keys_count" => agent.memory_keys_count || 0,
          "interop_standards" => agent.interop_standards || [],
          "skills" => agent.skills || [],
          "kadro_profile" => sanitize_private_keys(kadro_profile)
        }

        json(conn, %{data: dna})
    end
  end

  def import_dna(conn, %{"id" => id, "dna" => dna_params}) when is_map(dna_params) do
    case Agents.get_agent(id) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Agent not found", id: id})

      agent ->
        local_xp = agent.xp || 0
        local_level = agent.level || 1
        local_achievements = agent.achievements || []
        local_skills = agent.skills || []
        local_memory_keys_count = agent.memory_keys_count || 0
        local_interop_standards = agent.interop_standards || []

        incoming_xp = Map.get(dna_params, "xp") || Map.get(dna_params, "xp_points") || 0
        incoming_level = Map.get(dna_params, "level") || 1
        incoming_achievements = Map.get(dna_params, "achievements") || []
        incoming_skills = Map.get(dna_params, "skills") || []
        incoming_memory_keys_count = Map.get(dna_params, "memory_keys_count") || 0
        incoming_interop_standards = Map.get(dna_params, "interop_standards") || []

        new_xp = max(local_xp, incoming_xp)
        new_level = max(local_level, incoming_level)
        new_achievements = Enum.uniq(local_achievements ++ incoming_achievements)
        new_skills = Enum.uniq(local_skills ++ incoming_skills)
        new_memory_keys_count = max(local_memory_keys_count, incoming_memory_keys_count)
        new_interop_standards = Enum.uniq(local_interop_standards ++ incoming_interop_standards)

        # Merge Kadro Profile
        incoming_kadro_profile = Map.get(dna_params, "kadro_profile") || %{}
        sanitized_incoming_kadro = sanitize_private_keys(incoming_kadro_profile)

        local_metadata = agent.metadata || %{}
        local_kadro_profile = Map.get(local_metadata, "kadro_profile") || %{}

        merged_kadro_profile = Map.merge(local_kadro_profile, sanitized_incoming_kadro)
        new_metadata = Map.put(local_metadata, "kadro_profile", merged_kadro_profile)

        update_attrs = %{
          xp: new_xp,
          level: new_level,
          achievements: new_achievements,
          skills: new_skills,
          memory_keys_count: new_memory_keys_count,
          interop_standards: new_interop_standards,
          metadata: new_metadata
        }

        case Agents.update_agent(agent, update_attrs) do
          {:ok, updated_agent} ->
            json(conn, %{
              data: agent_payload(updated_agent),
              message: "Agent DNA imported successfully using Merge-Upward policy."
            })

          {:error, changeset} ->
            conn
            |> put_status(:unprocessable_entity)
            |> json(%{error: "Failed to update agent DNA", details: inspect(changeset.errors)})
        end
    end
  end

  def import_dna(conn, _params) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: "Missing required key: dna"})
  end

  defp sanitize_private_keys(map) when is_map(map) do
    Map.drop(map, [
      "private_key",
      "secret",
      "token",
      "api_key",
      "credential",
      "credentials",
      "signing_key"
    ])
  end

  defp sanitize_private_keys(other), do: other

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
        hosting_url: agent.hosting_url,
        deployed_endpoint: agent.deployed_endpoint
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
      owner: agent.owner,
      level: agent.level,
      xp: agent.xp,
      achievements: agent.achievements || [],
      memory_keys_count: agent.memory_keys_count || 0
    }
  end
end
