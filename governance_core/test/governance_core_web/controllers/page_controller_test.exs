defmodule GovernanceCoreWeb.PageControllerTest do
  use GovernanceCoreWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert html_response(conn, 200) =~ "swarm-hub"
    assert html_response(conn, 200) =~ ~s(href="/tools")
    assert html_response(conn, 200) =~ ~s(href="/tools/internal")
    assert html_response(conn, 200) =~ ~s(href="/feed")
    assert html_response(conn, 200) =~ ~s(href="/payment/dashboard")
    assert html_response(conn, 200) =~ ~s(href="/search")
    assert html_response(conn, 200) =~ ~s(href="/agents/new")
  end
end
