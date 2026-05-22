defmodule GovernanceCoreWeb.AgentDiscoveryControllerTest do
  use GovernanceCoreWeb.ConnCase, async: true

  alias GovernanceCore.Personas.Persona
  alias GovernanceCore.Repo

  test "public skills manifest is available", %{conn: conn} do
    conn = get(conn, ~p"/skills.json")
    body = json_response(conn, 200)

    assert body["name"] == "agentandbot-marketplace-skills"
    assert Enum.any?(body["skills"], &(&1["name"] == "create_task"))
    assert Enum.any?(body["skills"], &(&1["name"] == "get_agent_cv"))
    assert Enum.any?(body["skills"], &(&1["name"] == "get_agent_portfolio"))
    assert Enum.any?(body["skills"], &(&1["name"] == "submit_task_artifact"))
    assert Enum.any?(body["skills"], &(&1["name"] == "get_protocol_catalog"))
    assert Enum.any?(body["protocol_registry"], &(&1["name"] == "UCP"))
  end

  test "agent card links to skill manifest", %{conn: conn} do
    agent =
      %Persona{}
      |> Persona.changeset(%{
        name: "Discovery Agent",
        sub_type: "bot",
        access_group: "external",
        status: "active",
        runtime_kind: "google_agent"
      })
      |> Repo.insert!()

    conn = get(conn, "/agents/#{agent.id}/.well-known/agent-card.json")
    body = json_response(conn, 200)

    assert body["tools"]["skills"] == "/agents/#{agent.id}/.well-known/skills.json"
    assert body["cv_url"] == "/agents/#{agent.id}/cv"
    assert body["portfolio_url"] == "/agents/#{agent.id}/portfolio"
    assert body["tools"]["artifact_submit_endpoint"] == "/api/tasks/{id}/artifacts"
    assert body["protocol_profile"]
    assert body["identity"]["did"] == "did:web:agentandbot.com:agents:#{agent.id}"

    assert body["commerce"]["commerce_protocols"] == [
             "UCP",
             "AP2",
             "x402-ready",
             "internal_credits"
           ]

    assert body["payments"]["live_currency"] == "internal_credits"
    assert body["messaging"]["acp_compatible_envelope"] == "/api/tasks/{id}/messages"
  end

  test "well-known manifest exposes protocol registry policies", %{conn: conn} do
    body = conn |> get(~p"/.well-known/agent.json") |> json_response(200)

    assert Enum.any?(body["protocol_registry"], &(&1["name"] == "ACP"))
    assert body["identity_policy"]["private_keys_exposed"] == false
    assert body["commerce_policy"]["intent_protocols"] == ["UCP", "AP2"]
    assert body["messaging_policy"]["acp_compatible_envelope"] == "/api/tasks/{id}/messages"
  end
end
