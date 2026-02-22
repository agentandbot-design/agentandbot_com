defmodule GovernanceCoreWeb.PageController do
  use GovernanceCoreWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
