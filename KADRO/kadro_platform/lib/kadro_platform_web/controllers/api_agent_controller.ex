defmodule KadroPlatformWeb.ApiAgentController do
  use KadroPlatformWeb, :controller

  alias KadroPlatform.Registry

  def index(conn, _params) do
    agents =
      Registry.list_agents(limit: 120)
      |> Enum.map(fn agent ->
        %{
          uuid: agent.uuid,
          public_id: agent.public_id,
          p_no: agent.p_no,
          name: agent.name,
          profession: agent.profession,
          category: agent.category,
          country: agent.country,
          status: agent.status,
          ai_disclosure_required: agent.ai_disclosure_required,
          agent_card_url: ~p"/agents/#{agent.public_id}/.well-known/agent-card.json"
        }
      end)

    json(conn, %{data: agents})
  end
end
