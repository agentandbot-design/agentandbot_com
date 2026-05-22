defmodule GovernanceCoreWeb.InternalToolControllerTest do
  use GovernanceCoreWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  test "internal tools UI and API expose safe metadata", %{conn: conn} do
    html = conn |> get(~p"/tools/internal") |> html_response(200)

    assert html =~ "Internal Tools"
    assert html =~ "Windmill"
    assert html =~ "Stored in vault"
    refute html =~ "vault://e-any/windmill/admin"
    refute html =~ "20911980"

    payload = conn |> get(~p"/api/internal-tools") |> json_response(200)
    names = Enum.map(payload["data"], & &1["name"])

    assert "Windmill" in names
    assert "database" in payload["categories"]

    Enum.each(payload["data"], fn tool ->
      refute Map.has_key?(tool, "secrets_ref")
    end)

    windmill = conn |> get(~p"/api/internal-tools/windmill") |> json_response(200)
    assert windmill["data"]["agent_access"] == "true"
    assert windmill["data"]["health"] == "running"
    assert windmill["data"]["metadata"]["mcp_path"] == "/api/mcp/w/admins/mcp"

    assert windmill["data"]["metadata"]["recommended_flows_endpoint"] ==
             "/api/internal-tools/windmill/flows"

    refute Map.has_key?(windmill["data"], "secrets_ref")
    refute inspect(windmill) =~ "token="
    refute inspect(windmill) =~ "vault://"

    flows = conn |> get(~p"/api/internal-tools/windmill/flows") |> json_response(200)
    flow_ids = Enum.map(flows["data"]["flows"], & &1["id"])

    assert "feed-ingestion" in flow_ids
    assert "cv-generator-render" in flow_ids
    assert flows["data"]["mcp_path"] == "/api/mcp/w/admins/mcp"
    refute inspect(flows) =~ "token="
    refute inspect(flows) =~ "vault://"

    activepieces = conn |> get(~p"/api/internal-tools/activepieces/flows") |> json_response(200)
    activepieces_flow_ids = Enum.map(activepieces["data"]["flows"], & &1["id"])

    assert activepieces["data"]["mcp_url"] == "https://cloud.activepieces.com/mcp/platform"
    assert activepieces["data"]["auth_mode"] == "oauth"

    assert activepieces["data"]["client_config"]["mcpServers"]["activepieces"]["url"] ==
             "https://cloud.activepieces.com/mcp/platform"

    assert "social-crosspost" in activepieces_flow_ids
    assert "form-to-feed" in activepieces_flow_ids
    refute inspect(activepieces) =~ "client_secret"
    refute inspect(activepieces) =~ "access_token"
    refute inspect(activepieces) =~ "vault://"

    {:ok, view, _html} = live(conn, ~p"/tools/internal")
    filtered = render_change(view, :filter, %{"search" => "postgres"})
    assert filtered =~ "PostgreSQL"
  end

  test "skills and openapi include internal tools metadata capability", %{conn: conn} do
    skills = conn |> get(~p"/skills.json") |> json_response(200)
    names = Enum.map(skills["skills"], & &1["name"])

    assert "search_internal_tools" in names

    openapi = conn |> get(~p"/api/openapi.json") |> json_response(200)
    assert Map.has_key?(openapi["paths"], "/api/internal-tools")
    assert Map.has_key?(openapi["paths"], "/api/internal-tools/activepieces/flows")
    assert Map.has_key?(openapi["paths"], "/api/internal-tools/windmill/flows")
    assert Map.has_key?(openapi["paths"], "/api/internal-tools/{slug}")
    assert Map.has_key?(openapi["components"]["schemas"], "InternalTool")
    assert Map.has_key?(openapi["components"]["schemas"], "ActivepiecesFlowCatalog")
    assert Map.has_key?(openapi["components"]["schemas"], "WindmillFlowCatalog")
  end
end
