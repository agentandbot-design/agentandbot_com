defmodule GovernanceCore.MarketplaceTest do
  use GovernanceCore.DataCase, async: true

  alias GovernanceCore.Marketplace
  alias GovernanceCore.Personas.Persona
  alias GovernanceCore.Repo

  setup do
    agent =
      %Persona{}
      |> Persona.changeset(%{
        name: "Hireable Agent",
        sub_type: "bot",
        access_group: "external",
        status: "active",
        owner: "agent_owner",
        runtime_kind: "hermes",
        skills: ["deliver_artifact"]
      })
      |> Repo.insert!()

    Marketplace.upsert_policy(%{
      persona_id: agent.id,
      allowed_skills: ["deliver_artifact"],
      max_budget_credits: 50
    })

    {:ok, agent: agent}
  end

  test "creating task with enough credits creates escrow hold", %{agent: agent} do
    {:ok, _entry} = Marketplace.adjust_credits("buyer", 25)

    assert {:ok, task} =
             Marketplace.create_task(%{
               agent_id: agent.id,
               created_by: "buyer",
               title: "Create report",
               required_skill: "deliver_artifact",
               budget_credits: 10
             })

    assert task.status == "escrowed"
    assert Marketplace.available_credits("buyer") == 15
  end

  test "insufficient credits returns payment error", %{agent: agent} do
    assert {:error, :insufficient_credits} =
             Marketplace.create_task(%{
               agent_id: agent.id,
               created_by: "buyer",
               title: "Create report",
               required_skill: "deliver_artifact",
               budget_credits: 10
             })
  end

  test "completed task releases credits to owner", %{agent: agent} do
    Marketplace.adjust_credits("buyer", 25)

    {:ok, task} =
      Marketplace.create_task(%{
        agent_id: agent.id,
        created_by: "buyer",
        title: "Create report",
        required_skill: "deliver_artifact",
        budget_credits: 10
      })

    assert {:ok, completed} =
             Marketplace.record_event(task.id, "completed", %{"actor" => agent.id})

    assert completed.status == "completed"
    assert Marketplace.available_credits("agent_owner") == 10
  end

  test "submitted public artifact appears in agent portfolio", %{agent: agent} do
    Marketplace.adjust_credits("buyer", 25)

    {:ok, task} =
      Marketplace.create_task(%{
        agent_id: agent.id,
        created_by: "buyer",
        title: "Create public artifact",
        required_skill: "deliver_artifact",
        budget_credits: 10
      })

    assert {:ok, artifact_task} =
             Marketplace.submit_artifact(task.id, %{
               "actor" => agent.id,
               "artifact_url" => "https://example.com/public-artifact",
               "artifact_type" => "report",
               "summary" => "Published portfolio report.",
               "portfolio_public" => true
             })

    assert artifact_task.status == "artifact_submitted"

    portfolio = Marketplace.agent_portfolio(agent.id)
    assert [%{title: "Create public artifact", artifact_type: "report"}] = portfolio.entries
  end

  test "rejected task refunds escrow", %{agent: agent} do
    Marketplace.adjust_credits("buyer", 25)

    {:ok, task} =
      Marketplace.create_task(%{
        agent_id: agent.id,
        created_by: "buyer",
        title: "Create report",
        required_skill: "deliver_artifact",
        budget_credits: 10
      })

    assert {:ok, refunded} = Marketplace.record_event(task.id, "rejected", %{"actor" => agent.id})
    assert refunded.status == "refunded"
    assert Marketplace.available_credits("buyer") == 25
  end

  test "delegation creates child task and records event", %{agent: agent} do
    target =
      %Persona{}
      |> Persona.changeset(%{
        name: "Delegate Target",
        sub_type: "bot",
        access_group: "external",
        status: "active",
        runtime_kind: "openclaw",
        skills: ["handoff_task"]
      })
      |> Repo.insert!()

    Marketplace.upsert_policy(%{persona_id: target.id, allowed_skills: ["handoff_task"]})
    Marketplace.adjust_credits("buyer", 25)

    {:ok, task} =
      Marketplace.create_task(%{
        agent_id: agent.id,
        created_by: "buyer",
        title: "Create report",
        required_skill: "deliver_artifact",
        budget_credits: 10
      })

    assert {:ok, child} =
             Marketplace.delegate_task(task.id, %{
               "from_agent_id" => agent.id,
               "to_agent_id" => target.id,
               "required_skill" => "handoff_task",
               "reason" => "Needs channel handoff"
             })

    assert child.delegated_from_task_id == task.id
    source = Marketplace.get_task(task.id)
    assert Enum.any?(source.events, &(&1.event_type == "delegated"))
  end

  test "task messages and commerce intents record metadata events", %{agent: agent} do
    Marketplace.adjust_credits("buyer", 25)

    {:ok, task} =
      Marketplace.create_task(%{
        agent_id: agent.id,
        created_by: "buyer",
        title: "Coordinate work",
        required_skill: "deliver_artifact",
        budget_credits: 10
      })

    assert {:ok, messaged} =
             Marketplace.send_task_message(task.id, %{
               "from_agent_id" => "buyer-agent",
               "to_agent_id" => agent.id,
               "protocol" => "ACP",
               "message" => "Please confirm scope."
             })

    assert Enum.any?(messaged.events, &(&1.event_type == "message"))

    assert {:ok, commerce} =
             Marketplace.create_commerce_intent(task.id, %{
               "intent" => "Buy one task result",
               "budget_credits" => 10
             })

    event = Enum.find(commerce.events, &(&1.event_type == "commerce_intent"))
    assert get_in(event.metadata, ["commerce_intent", "protocols"]) == ["UCP", "AP2"]
  end
end
