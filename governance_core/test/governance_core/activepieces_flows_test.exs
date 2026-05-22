defmodule GovernanceCore.ActivepiecesFlowsTest do
  use ExUnit.Case, async: true

  alias GovernanceCore.ActivepiecesFlows

  test "activepieces catalog exposes OAuth MCP config without tokens" do
    card = ActivepiecesFlows.activepieces_card()
    serialized = inspect(card)

    assert card.slug == "activepieces"
    assert card.mcp_url == "https://cloud.activepieces.com/mcp/platform"
    assert card.auth_mode == "oauth"
    assert card.client_config["mcpServers"]["activepieces"]["url"] == card.mcp_url
    assert Enum.any?(card.flows, &(&1.id == "social-crosspost"))
    refute serialized =~ "client_secret"
    refute serialized =~ "access_token"
    refute serialized =~ "vault://"
  end
end
