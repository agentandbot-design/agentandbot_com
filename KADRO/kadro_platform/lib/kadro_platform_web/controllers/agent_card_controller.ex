defmodule KadroPlatformWeb.AgentCardController do
  use KadroPlatformWeb, :controller

  alias KadroPlatform.Registry

  def show(conn, %{"public_id" => public_id}) do
    agent = Registry.get_agent_by_public_id!(public_id)
    json(conn, Registry.agent_card(agent))
  end
end
