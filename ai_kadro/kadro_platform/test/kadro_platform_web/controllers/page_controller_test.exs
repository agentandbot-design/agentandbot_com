defmodule KadroPlatformWeb.PageControllerTest do
  use KadroPlatformWeb.ConnCase

  test "GET /", %{conn: conn} do
    conn = get(conn, ~p"/")
    assert redirected_to(conn) == ~p"/agents"
  end
end
