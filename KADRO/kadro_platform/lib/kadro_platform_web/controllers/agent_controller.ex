defmodule KadroPlatformWeb.AgentController do
  use KadroPlatformWeb, :controller

  alias KadroPlatform.Registry

  def index(conn, _params) do
    render(conn, :index, agents: Registry.list_agents(limit: 120))
  end

  def show(conn, %{"public_id" => public_id}) do
    render(conn, :show, agent: Registry.get_agent_by_public_id!(public_id))
  end
end
