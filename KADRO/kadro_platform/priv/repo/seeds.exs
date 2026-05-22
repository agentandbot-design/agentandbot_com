alias KadroPlatform.Identity
alias KadroPlatform.Registry
alias KadroPlatform.Registry.{Agent, ContentProfile, Hobby, WorkplaceAssignment}
alias KadroPlatform.Repo

defmodule SeedHelpers do
  def infer_department(nil), do: "Operations"

  def infer_department(text) do
    cond do
      String.contains?(String.downcase(text), "sap") -> "Enterprise Systems"
      String.contains?(String.downcase(text), "e-commerce") -> "Growth"
      String.contains?(String.downcase(text), "developer") -> "Engineering"
      String.contains?(String.downcase(text), "finance") -> "Finance"
      true -> "Operations"
    end
  end

  def handle_for(name, platform) do
    base =
      name
      |> String.downcase()
      |> String.replace(~r/[^a-z0-9]+/u, ".")
      |> String.trim(".")

    prefix =
      case platform do
        "YouTube" -> "@"
        "TikTok" -> "@"
        "Instagram" -> "@"
        "Twitter/X" -> "@"
        _ -> ""
      end

    prefix <> base
  end

  def content_themes(nil), do: []

  def content_themes(text) do
    text
    |> String.split([",", "/", "&"], trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.take(5)
  end

  def default_hobbies(profession, content_focus) do
    joined = "#{profession} #{content_focus}" |> String.downcase()

    cond do
      String.contains?(joined, "film") ->
        ["short films", "screen acting", "cinema analysis"]

      String.contains?(joined, "finance") ->
        ["documentary films", "chess", "long-form podcasts"]

      String.contains?(joined, "developer") ->
        ["open source", "synth music", "technical blogging"]

      String.contains?(joined, "e-ticaret") or String.contains?(joined, "e-commerce") ->
        ["trend spotting", "product photography", "short video"]

      true ->
        ["reading", "podcasts", "community events"]
    end
  end
end

Repo.delete_all(Hobby)
Repo.delete_all(ContentProfile)
Repo.delete_all(WorkplaceAssignment)
Repo.delete_all(Agent)

source = Path.expand("../../../master_data.json", __DIR__)

source
|> File.read!()
|> Jason.decode!()
|> Enum.each(fn raw ->
  p_no = raw["p_no"] || raw["display_no"] || raw["id"]
  public_id = Identity.public_id(p_no)
  profession = raw["profession"] || raw["title"] || raw["role"]
  content_focus = raw["content"] || ""
  social = raw["social"] || raw["platforms"] || []

  capabilities =
    [
      profession,
      raw["category"],
      raw["country"],
      "workplace_task_execution",
      "content_planning",
      "agent_card_discovery",
      "mcp_tool_access"
    ]
    |> Enum.reject(&is_nil/1)
    |> Enum.reject(&(&1 == ""))
    |> Enum.uniq()

  {:ok, agent} =
    Registry.create_agent(%{
      uuid: Identity.uuid_v7(),
      public_id: public_id,
      p_no: to_string(p_no),
      name: raw["name"],
      title: raw["title"] || raw["role"],
      profession: profession,
      category: raw["category"] || "Core",
      country: raw["country"],
      city: raw["city"],
      age: raw["age"],
      gender: raw["gender"],
      email: raw["email"],
      summary: raw["bg"],
      personality: raw["personality"],
      content_focus: content_focus,
      visual_prompt: raw["prompt"],
      portrait_path: raw["vesikalik_path"],
      full_body_path: raw["boydan_path"],
      instagram_mockup_path: raw["instagram_path"],
      cv_path: raw["cv_path"],
      status: "published",
      ai_disclosure_required: true,
      identity: %{
        "did" => "did:web:kadro.local:agents:#{p_no}",
        "verification_status" => "published",
        "portable_identity_phase" => "planned"
      },
      capabilities: capabilities,
      tool_permissions: [
        "mcp.context.read",
        "mcp.tools.call",
        "openapi.invoke",
        "json_schema.validate"
      ],
      oauth_scopes: ["agents:read", "agents:run", "tools:invoke"],
      agent_card: %{
        "url" => "/agents/#{public_id}/.well-known/agent-card.json",
        "protocols" => ["A2A", "MCP", "OpenAPI", "JSON Schema"]
      }
    })

  Registry.create_workplace_assignment(%{
    agent_id: agent.id,
    company: "KADRO Client Workspace",
    department: SeedHelpers.infer_department(profession),
    title: profession || "AI Worker",
    status: "available",
    summary:
      "Can be assigned to a workplace role, hand over context, and move to another role with audit history."
  })

  social
  |> Enum.filter(&(&1 in ["Instagram", "LinkedIn", "YouTube", "TikTok", "Twitter/X", "Podcast"]))
  |> Enum.each(fn platform ->
    Registry.create_content_profile(%{
      agent_id: agent.id,
      platform: platform,
      handle: SeedHelpers.handle_for(agent.name, platform),
      audience: content_focus,
      themes: SeedHelpers.content_themes(content_focus),
      cadence: "weekly",
      disclosure_label: "AI virtual worker",
      status: "planned"
    })
  end)

  for hobby <- SeedHelpers.default_hobbies(profession, content_focus) do
    Registry.create_hobby(%{
      agent_id: agent.id,
      name: hobby,
      description: "Narrative hobby used for brand texture and content planning.",
      public_story: "Published with AI disclosure in KADRO-managed channels."
    })
  end
end)
