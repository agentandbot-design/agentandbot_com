defmodule GovernanceCoreWeb.Api.InternalToolController do
  use GovernanceCoreWeb, :controller

  alias GovernanceCore.{ActivepiecesFlows, InternalTools, WindmillFlows}

  def index(conn, params) do
    tools =
      InternalTools.list_tools(
        category: Map.get(params, "category", "all"),
        agent_access: Map.get(params, "agent_access", "all")
      )
      |> Enum.map(&sanitize/1)

    json(conn, %{data: tools, categories: InternalTools.categories()})
  end

  def show(conn, %{"slug" => slug}) do
    case InternalTools.get_tool(slug) do
      nil ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Internal tool not found"})

      tool ->
        json(conn, %{data: sanitize(tool)})
    end
  end

  def windmill_flows(conn, _params) do
    json(conn, %{data: WindmillFlows.windmill_card()})
  end

  def activepieces_flows(conn, _params) do
    json(conn, %{data: ActivepiecesFlows.activepieces_card()})
  end

  defp sanitize(tool) when is_map(tool) do
    tool
    |> Map.delete(:secrets_ref)
    |> Map.delete("secrets_ref")
  end
end
