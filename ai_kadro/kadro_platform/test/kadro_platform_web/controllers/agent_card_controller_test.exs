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
  end
end
