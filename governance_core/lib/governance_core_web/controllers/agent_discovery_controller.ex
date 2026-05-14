defmodule GovernanceCoreWeb.AgentDiscoveryController do
  use GovernanceCoreWeb, :controller

  def show(conn, _params) do
    discovery_data = %{
      schema_version: "1.0",
      name: "agentandbot.com",
      description: "Governance Core for agentandbot.com AI ecosystem.",
      contact: "admin@agentandbot.com",
      protocols: %{
        clawspeak: %{
          version: "0.1-alpha",
          description: "High-density semantic layer for agent intent negotiation.",
          repository: "https://github.com/agentandbot-design/dil"
        },
        ump: %{
          version: "0.1",
          description: "Ultra Mini Agent Protocol for binary data transit.",
          repository: "https://github.com/agentandbot-design/dil/tree/main/ump"
        }
      },
      skills_url: "https://agentandbot.com/api/skills",
      rules_of_engagement: [
        "All transactions must be logged via ClawSpeak.",
        "Resource quotas are strictly enforced.",
        "Unauthenticated agents run in sandbox mode."
      ]
    }

    conn
    |> put_resp_content_type("application/json")
    |> json(discovery_data)
  end
end
