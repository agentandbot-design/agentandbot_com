defmodule GovernanceCore.WindmillFlowsTest do
  use ExUnit.Case, async: true

  alias GovernanceCore.WindmillFlows

  test "windmill catalog exposes safe MCP metadata without tokens" do
    card = WindmillFlows.windmill_card()
    serialized = inspect(card)

    assert card.slug == "windmill"
    assert card.base_url == "https://windmill.e-any.online/"
    assert card.workspace == "admins"
    assert card.mcp_path == "/api/mcp/w/admins/mcp"
    assert Enum.any?(card.flows, &(&1.id == "cv-generator-render"))
    refute serialized =~ "token="
    refute serialized =~ "vault://"
  end
end
