defmodule GovernanceCore.ActivepiecesFlows do
  @moduledoc """
  Safe catalog of workflows that should be orchestrated through Activepieces.

  Activepieces MCP access is OAuth based. This module exposes only the public MCP
  server URL and client configuration shape; no OAuth tokens or user credentials.
  """

  @base_url "https://cloud.activepieces.com/"
  @mcp_url "https://cloud.activepieces.com/mcp/platform"

  @flows [
    %{
      id: "social-crosspost",
      name: "Social Crosspost",
      status: "ready_to_build",
      priority: "high",
      owner: "content_ops",
      trigger: "manual_or_scheduled",
      agent_scopes: ["workflow:run", "feed:read", "social:write"],
      inputs: ["feed_post_id", "platforms", "caption", "media_url"],
      outputs: ["platform_post_urls", "publish_report"],
      recommended_for: [
        "LinkedIn/Twitter style announcements",
        "Pinterest or visual asset posting",
        "human-reviewed social publishing"
      ],
      notes: "Keep final approval in AgentAndBot before publishing to human-owned channels."
    },
    %{
      id: "form-to-feed",
      name: "Form To Feed Intake",
      status: "ready_to_build",
      priority: "high",
      owner: "content_ops",
      trigger: "webhook",
      agent_scopes: ["workflow:run", "feed:write"],
      inputs: ["form_payload", "source_site", "author_email"],
      outputs: ["draft_feed_post", "moderation_hint"],
      recommended_for: [
        "blog/news submissions",
        "partner announcements",
        "agent/customer intake forms"
      ],
      notes: "Activepieces handles app connectors; AgentAndBot owns moderation and publication."
    },
    %{
      id: "database-form-sync",
      name: "Database And Form Sync",
      status: "candidate",
      priority: "medium",
      owner: "internal_ops",
      trigger: "scheduled_or_webhook",
      agent_scopes: ["workflow:run", "forms:read", "db:write_limited"],
      inputs: ["form_id", "target_table", "mapping"],
      outputs: ["sync_count", "sync_errors"],
      recommended_for: [
        "internal tool forms",
        "CRM/contact sync",
        "lightweight operational databases"
      ],
      notes:
        "Use scoped credentials per connector; never share admin database credentials with generic flows."
    },
    %{
      id: "human-approval",
      name: "Human Approval Router",
      status: "candidate",
      priority: "medium",
      owner: "ops_admins",
      trigger: "event",
      agent_scopes: ["workflow:run", "approval:request"],
      inputs: ["approval_type", "artifact_url", "requester_id"],
      outputs: ["approval_status", "reviewer_note"],
      recommended_for: [
        "publishing approval",
        "refund review",
        "agent deployment approval"
      ],
      notes: "Approval decisions should be written back to AgentAndBot for auditability."
    }
  ]

  def activepieces_card do
    %{
      slug: "activepieces",
      name: "Activepieces",
      base_url: @base_url,
      mcp_url: @mcp_url,
      auth_mode: "oauth",
      token_policy: "oauth_client_managed",
      token_location:
        "OAuth is handled by the MCP-compatible client; no token is stored in AgentAndBot.",
      client_config: %{
        "mcpServers" => %{
          "activepieces" => %{
            "url" => @mcp_url
          }
        }
      },
      flows: list_flows()
    }
  end

  def list_flows, do: @flows

  def get_flow(id), do: Enum.find(@flows, &(&1.id == id))
end
