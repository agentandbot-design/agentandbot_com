defmodule KadroPlatformWeb.AgentCardControllerTest do
  use KadroPlatformWeb.ConnCase

  alias KadroPlatform.Identity
  alias KadroPlatform.Registry

  test "GET agent card", %{conn: conn} do
    {:ok, _agent} =
      Registry.create_agent(%{
        uuid: Identity.uuid_v7(),
        public_id: "KADRO-T001",
        p_no: "T001",
        name: "Test Agent",
        category: "Core",
        status: "published",
        ai_disclosure_required: true,
        capabilities: ["workplace_task_execution"]
      })

    conn = get(conn, ~p"/agents/KADRO-T001/.well-known/agent-card.json")
    body = json_response(conn, 200)

    assert body["id"] == "KADRO-T001"
    assert body["disclosure"]["required"] == true
    assert "workplace_task_execution" in body["capabilities"]
    assert body["auth"]["type"] == "agentic_registration"
    assert "kadro:hire" in body["auth"]["scopes"]
  end

  test "GET KADRO auth discovery", %{conn: conn} do
    auth_md = conn |> get(~p"/auth.md") |> text_response(200)
    assert auth_md =~ "KADRO auth.md"
    assert auth_md =~ "contract_only_v1"

    protected =
      conn
      |> get(~p"/.well-known/oauth-protected-resource")
      |> json_response(200)

    assert protected["resource"] == "https://kadro.agentandbot.com/"
    assert "https://auth.agentandbot.com/" in protected["authorization_servers"]
    assert "kadro:hire" in protected["scopes_supported"]

    authorization =
      conn
      |> get(~p"/.well-known/oauth-authorization-server")
      |> json_response(200)

    assert authorization["issuer"] == "https://auth.agentandbot.com/"
    assert authorization["agent_auth"]["skill"] == "https://kadro.agentandbot.com/auth.md"
    assert authorization["agent_auth"]["kadro_profile"]["ai_disclosure_required"] == true
  end
end
