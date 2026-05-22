defmodule GovernanceCore.SwarmSearchTest do
  use GovernanceCore.DataCase, async: false

  alias GovernanceCore.{Feed, Marketplace, SwarmSearch}
  alias GovernanceCore.Payment.Payments
  alias GovernanceCore.Personas.Persona
  alias GovernanceCore.Repo

  setup do
    agent =
      %Persona{}
      |> Persona.changeset(%{
        name: "Atlas Research Bot",
        role: "Harezm knowledge scout",
        sub_type: "bot",
        access_group: "external",
        status: "active",
        owner: "atlas_owner",
        runtime_kind: "hermes",
        skills: ["research", "briefing"]
      })
      |> Repo.insert!()

    Marketplace.upsert_policy(%{
      persona_id: agent.id,
      allowed_skills: ["research"],
      max_budget_credits: 50
    })

    Marketplace.adjust_credits("buyer", 25)

    {:ok, _task} =
      Marketplace.create_task(%{
        agent_id: agent.id,
        created_by: "buyer",
        title: "Prepare Atlas market brief",
        required_skill: "research",
        budget_credits: 10
      })

    {:ok, post} =
      Feed.create_post(%{
        "title" => "Atlas launch notes",
        "summary" => "Searchable ecosystem dispatch",
        "author_type" => "system",
        "status" => "published"
      })

    {:ok, _service} =
      Payments.create_service(%{
        name: "Atlas Verify",
        slug: "atlas-verify",
        owner_wallet: "atlas_wallet",
        endpoint_url: "https://example.test/atlas",
        price_per_request: 7,
        active: true
      })

    {:ok, agent: agent, post: post}
  end

  test "returns grouped results across agents, tasks, feed, and services" do
    results = SwarmSearch.search("Atlas")

    assert results.total >= 4
    assert Enum.any?(results.groups.agents, &(&1.title == "Atlas Research Bot"))
    assert Enum.any?(results.groups.tasks, &(&1.title == "Prepare Atlas market brief"))
    assert Enum.any?(results.groups.feed, &(&1.title == "Atlas launch notes"))
    assert Enum.any?(results.groups.services, &(&1.title == "Atlas Verify"))
  end

  test "includes internal e-any tools" do
    results = SwarmSearch.search("windmill")

    assert Enum.any?(results.groups.internal_tools, &(&1.title == "Windmill"))
  end

  test "blank query returns an empty result set" do
    assert %{total: 0, groups: groups} = SwarmSearch.search(" ")
    assert Enum.all?(Map.values(groups), &(&1 == []))
  end
end
