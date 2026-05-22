defmodule KadroPlatformWeb.PageController do
  use KadroPlatformWeb, :controller

  def home(conn, _params) do
    redirect(conn, to: ~p"/agents")
  end
end
