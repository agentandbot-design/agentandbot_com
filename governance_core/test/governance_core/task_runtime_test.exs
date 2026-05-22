defmodule GovernanceCore.TaskRuntimeTest do
  use GovernanceCore.DataCase, async: false

  alias GovernanceCore.Marketplace
  alias GovernanceCore.Personas.Persona
  alias GovernanceCore.Repo

  setup do
    agent =
      %Persona{}
      |> Persona.changeset(%{
        name: "Webhook Agent",
        sub_type: "bot",
        access_group: "external",
        status: "active",
        owner: "agent_owner",
        runtime_kind: "hermes",
        skills: ["deliver_artifact"],
        deployed_endpoint: "https://example.com/agent-webhook"
      })
      |> Repo.insert!()

    Marketplace.upsert_policy(%{
      persona_id: agent.id,
      allowed_skills: ["deliver_artifact"],
      max_budget_credits: 50
    })

    {:ok, agent: agent}
  end

  test "launch_real_task_runtime/1 returns task_not_found for non-existent tasks" do
    assert {:error, :task_not_found} = Marketplace.launch_real_task_runtime(Ecto.UUID.generate())
  end

  test "launch_real_task_runtime/1 returns error if agent has no deployed_endpoint" do
    agent_no_endpoint =
      %Persona{}
      |> Persona.changeset(%{
        name: "No Webhook Agent",
        sub_type: "bot",
        access_group: "external",
        status: "active",
        owner: "agent_owner",
        runtime_kind: "hermes",
        skills: ["deliver_artifact"]
      })
      |> Repo.insert!()

    Marketplace.upsert_policy(%{
      persona_id: agent_no_endpoint.id,
      allowed_skills: ["deliver_artifact"],
      max_budget_credits: 50
    })

    {:ok, _entry} = Marketplace.adjust_credits("buyer", 25)

    {:ok, task} =
      Marketplace.create_task(%{
        agent_id: agent_no_endpoint.id,
        created_by: "buyer",
        title: "No Endpoint Task",
        required_skill: "deliver_artifact",
        budget_credits: 10
      })

    assert {:error, :no_deployed_endpoint} = Marketplace.launch_real_task_runtime(task.id)
  end

  test "launch_real_task_runtime/1 successfully starts task when deployed_endpoint is set", %{
    agent: agent
  } do
    {:ok, _entry} = Marketplace.adjust_credits("buyer", 25)

    {:ok, task} =
      Marketplace.create_task(%{
        agent_id: agent.id,
        created_by: "buyer",
        title: "Real Webhook Task",
        required_skill: "deliver_artifact",
        budget_credits: 10
      })

    assert {:ok, launched_task} = Marketplace.launch_real_task_runtime(task.id)
    assert launched_task.id == task.id
  end
end
