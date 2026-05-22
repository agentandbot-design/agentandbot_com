defmodule KadroPlatform.Registry do
  @moduledoc "Agent registry, workplace lifecycle, and public interoperability metadata."

  import Ecto.Query

  alias KadroPlatform.Repo
  alias KadroPlatform.Registry.{Agent, ContentProfile, Hobby, WorkplaceAssignment}

  def list_agents(opts \\ []) do
    limit = Keyword.get(opts, :limit, 60)

    Agent
    |> order_by([a], asc: a.p_no)
    |> limit(^limit)
    |> Repo.all()
  end

  def list_published_agents do
    Agent
    |> where([a], a.status == "published")
    |> order_by([a], asc: a.p_no)
    |> Repo.all()
  end

  def get_agent_by_public_id!(public_id) do
    Agent
    |> where([a], a.public_id == ^public_id)
    |> preload([:workplace_assignments, :content_profiles, :hobbies])
    |> Repo.one!()
  end

  def create_agent(attrs) do
    %Agent{}
    |> Agent.changeset(attrs)
    |> Repo.insert()
  end

  def create_workplace_assignment(attrs) do
    %WorkplaceAssignment{}
    |> WorkplaceAssignment.changeset(attrs)
    |> Repo.insert()
  end

  def create_content_profile(attrs) do
    %ContentProfile{}
    |> ContentProfile.changeset(attrs)
    |> Repo.insert()
  end

  def create_hobby(attrs) do
    %Hobby{}
    |> Hobby.changeset(attrs)
    |> Repo.insert()
  end

  def agent_card(%Agent{} = agent) do
    %{
      "schema_version" => "0.1",
      "id" => agent.public_id,
      "name" => agent.name,
      "description" => agent.summary || agent.personality,
      "provider" => %{"name" => "KADRO"},
      "url" => "/agents/#{agent.public_id}",
      "version" => "0.1.0",
      "identity" =>
        Map.merge(%{"uuid" => agent.uuid, "public_id" => agent.public_id}, agent.identity || %{}),
      "capabilities" => agent.capabilities || [],
      "skills" => build_skills(agent),
      "tools" => %{
        "mcp" => agent.tool_permissions || [],
        "openapi" => "/api/openapi.json"
      },
      "auth" => %{
        "type" => "oauth2_oidc",
        "scopes" => agent.oauth_scopes || []
      },
      "disclosure" => %{
        "required" => agent.ai_disclosure_required,
        "label" => "AI virtual worker"
      }
    }
  end

  defp build_skills(agent) do
    base =
      [agent.profession, agent.title, agent.content_focus]
      |> Enum.reject(&is_nil/1)
      |> Enum.reject(&(&1 == ""))

    Enum.uniq(base ++ (agent.capabilities || []))
  end
end
