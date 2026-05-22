alias GovernanceCore.Personas.Persona
alias GovernanceCore.KadroProfiles
alias GovernanceCore.Marketplace
alias GovernanceCore.Marketplace.AgentListing
alias GovernanceCore.Repo
alias GovernanceCore.RuntimeCatalog

agents = [
  %{
    name: "Hermes Business Operator",
    role: "General operations agent",
    type: "hermes",
    runtime_kind: "hermes",
    runtime_provider: "Hermes",
    hosting_mode: "affiliate",
    hosting_url: "https://www.hostinger.com/",
    category: "Enterprise",
    description:
      "Coordinates business workflows, reads task briefs, and delegates specialist work to other agents.",
    skills: ["A2A", "MCP", "OpenAPI 3.1", "JSON Schema", "x402-ready"],
    interop_standards: ["A2A", "MCP", "OpenAPI 3.1", "JSON Schema", "x402"],
    price_monthly: 19
  },
  %{
    name: "Agent-Zero Research Worker",
    role: "Research and tool automation agent",
    type: "agent_zero",
    runtime_kind: "agent_zero",
    runtime_provider: "Agent-Zero",
    hosting_mode: "external",
    category: "Research",
    description: "Runs tool-heavy research tasks through a user-managed Agent-Zero runtime.",
    skills: ["MCP", "OpenAPI 3.1", "JSON Schema", "research", "automation"],
    interop_standards: ["MCP", "OpenAPI 3.1", "JSON Schema"],
    price_monthly: 0
  },
  %{
    name: "OpenClaw Swarm Courier",
    role: "Agent-to-agent handoff specialist",
    type: "openclaw",
    runtime_kind: "openclaw",
    runtime_provider: "OpenClaw / Clawbot",
    hosting_mode: "affiliate",
    hosting_url: "https://www.hostinger.com/",
    category: "Communication",
    description: "Uses lightweight ClawSpeak-style task handoffs for swarm communication.",
    skills: ["A2A", "ClawSpeak", "ABL.ONE", "x402-ready"],
    interop_standards: ["A2A", "ClawSpeak", "ABL.ONE", "x402"],
    price_monthly: 9
  }
]

profile_skill_tags = fn profession ->
  profession
  |> to_string()
  |> String.downcase()
  |> then(fn text ->
    [
      if(String.contains?(text, "sap"), do: "SAP"),
      if(String.contains?(text, "e-commerce") or String.contains?(text, "ticaret"),
        do: "commerce"
      ),
      if(String.contains?(text, "developer") or String.contains?(text, "yazılım"),
        do: "software"
      ),
      if(String.contains?(text, "growth"), do: "growth"),
      if(String.contains?(text, "social") or String.contains?(text, "creator"), do: "content")
    ]
  end)
  |> Enum.reject(&is_nil/1)
end

Enum.each(agents, fn attrs ->
  attrs =
    Map.merge(
      %{
        sub_type: "bot",
        access_group: "external",
        status: "active",
        trust_score: 90,
        owner: "agentandbot",
        metadata: %{"execution" => "external_hosting_affiliate"}
      },
      attrs
    )

  agent =
    case Repo.get_by(Persona, name: attrs.name) do
      nil ->
        %Persona{}
        |> Persona.changeset(attrs)
        |> Repo.insert!()

      persona ->
        persona
        |> Persona.changeset(attrs)
        |> Repo.update!()
    end

  runtime = RuntimeCatalog.get_runtime(agent.runtime_kind)

  Marketplace.upsert_policy(%{
    persona_id: agent.id,
    allowed_scopes: ["agents:read", "tasks:assign", "tools:invoke"],
    allowed_skills: runtime.default_skills ++ agent.skills,
    max_budget_credits: 100,
    external_endpoint: Map.get(agent.metadata || %{}, "external_endpoint")
  })

  listing_attrs = %{
    persona_id: agent.id,
    seller_id: "agentandbot",
    title: agent.name,
    summary: agent.description,
    source_type: "internal_persona",
    fulfillment_mode: "both",
    hosting_mode:
      if(agent.hosting_mode == "affiliate", do: "external_provider", else: "self_hosted"),
    status: "published",
    runtime_kind: agent.runtime_kind,
    provider_id: if(agent.hosting_url, do: "hostinger", else: nil),
    provider_url: agent.hosting_url,
    external_setup_url: agent.hosting_url,
    task_price_credits: max(agent.price_monthly || 5, 5),
    rental_price_credits: max((agent.price_monthly || 10) * 5, 25),
    rental_period: "monthly",
    configuration_schema: %{
      "fields" => [
        %{"name" => "goal", "label" => "Goal", "type" => "text"},
        %{"name" => "tone", "label" => "Tone", "type" => "text"},
        %{"name" => "delivery", "label" => "Delivery", "type" => "text"}
      ]
    },
    default_configuration: %{"tone" => "clear", "delivery" => "link or document"},
    required_skills: runtime.default_skills ++ Enum.take(agent.skills || [], 3),
    standards: agent.interop_standards
  }

  case Repo.get_by(AgentListing, title: agent.name) do
    nil ->
      Marketplace.create_listing(listing_attrs)

    listing ->
      Marketplace.update_listing(listing, listing_attrs)
  end
end)

Enum.each(KadroProfiles.profiles(), fn profile ->
  name = profile["name"]
  profession = profile["profession"]

  persona_attrs = %{
    name: name,
    role: profession,
    sub_type: "bot",
    access_group: "external",
    status: "active",
    runtime_kind: "custom_webhook",
    runtime_provider: "KADRO",
    category: profile["category"],
    description: profile["personality"],
    skills: Enum.take(profile["social"] || [], 4),
    trust_score: 80,
    owner: "agentandbot",
    metadata: %{
      "worker_kind" => "ai_worker_persona",
      "kadro_profile" => profile
    }
  }

  persona =
    case Repo.get_by(Persona, name: name) do
      nil ->
        %Persona{}
        |> Persona.changeset(persona_attrs)
        |> Repo.insert!()

      persona ->
        persona
        |> Persona.changeset(persona_attrs)
        |> Repo.update!()
    end

  skills =
    ["receive_task", "deliver_artifact"]
    |> Kernel.++(Enum.take(profile["social"] || [], 3))
    |> Kernel.++(profile_skill_tags.(profession))
    |> Enum.uniq()

  listing_attrs = %{
    persona_id: persona.id,
    seller_id: "agentandbot",
    title: name,
    summary: profession,
    source_type: "internal_persona",
    fulfillment_mode: "both",
    hosting_mode: "self_hosted",
    status: "published",
    runtime_kind: "custom_webhook",
    task_price_credits: 5,
    rental_price_credits: 50,
    rental_period: "monthly",
    configuration_schema: %{
      "fields" => [
        %{"name" => "goal", "label" => "Goal", "type" => "text"},
        %{"name" => "tone", "label" => "Tone", "type" => "text"},
        %{"name" => "delivery", "label" => "Delivery", "type" => "text"},
        %{"name" => "channel", "label" => "Preferred channel", "type" => "text"}
      ]
    },
    default_configuration: %{"tone" => "natural", "delivery" => "artifact link"},
    required_skills: skills,
    standards: ["MCP", "OpenAPI", "A2A", "x402-ready"],
    metadata: %{
      "worker_kind" => "ai_worker_persona",
      "kadro_profile" => profile
    }
  }

  case Repo.get_by(AgentListing, title: name) do
    nil -> Marketplace.create_listing(listing_attrs)
    listing -> Marketplace.update_listing(listing, listing_attrs)
  end
end)

if Marketplace.available_credits("local_user") == 0 do
  Marketplace.adjust_credits("local_user", 250, %{"source" => "seed"})
end
