defmodule GovernanceCoreWeb.TaskControllerTest do
  use GovernanceCoreWeb.ConnCase, async: true

  alias GovernanceCore.Marketplace
  alias GovernanceCore.Personas.Persona
  alias GovernanceCore.Repo

  setup do
    agent =
      %Persona{}
      |> Persona.changeset(%{
        name: "Callback Agent",
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

  test "callback endpoint transition to working, completed, and failed", %{
    conn: conn,
    agent: agent
  } do
    Marketplace.adjust_credits("buyer", 25)

    {:ok, task} =
      Marketplace.create_task(%{
        agent_id: agent.id,
        created_by: "buyer",
        title: "Test Callback Flow",
        required_skill: "deliver_artifact",
        budget_credits: 10
      })

    # Test working callback status
    conn1 =
      post(conn, ~p"/api/tasks/#{task.id}/callback", %{
        "status" => "working",
        "message" => "Working on report..."
      })

    body1 = json_response(conn1, 200)
    assert body1["data"]["status"] == "working"

    assert Enum.any?(
             body1["data"]["events"],
             &(&1["event_type"] == "working" && &1["message"] == "Working on report...")
           )

    # Test failed callback status
    conn2 =
      post(conn, ~p"/api/tasks/#{task.id}/callback", %{
        "status" => "failed",
        "message" => "Encountered a runtime error"
      })

    body2 = json_response(conn2, 200)
    assert body2["data"]["status"] == "refunded"
    assert Marketplace.available_credits("buyer") == 25

    # Recreate task to test completed
    {:ok, task_completed} =
      Marketplace.create_task(%{
        agent_id: agent.id,
        created_by: "buyer",
        title: "Test Callback Completed Flow",
        required_skill: "deliver_artifact",
        budget_credits: 10
      })

    conn3 =
      post(conn, ~p"/api/tasks/#{task_completed.id}/callback", %{
        "status" => "completed",
        "artifact_url" => "/artifacts/report.md",
        "message" => "Success details",
        "portfolio_public" => true,
        "portfolio_summary" => "Done report summary"
      })

    body3 = json_response(conn3, 200)
    assert body3["data"]["status"] == "artifact_submitted"
    assert body3["data"]["artifact_url"] == "/artifacts/report.md"
  end
end
