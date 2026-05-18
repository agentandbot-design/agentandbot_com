defmodule GovernanceCore.SkillManifest do
  @moduledoc """
  Machine-readable skill contracts for humans, agents, and external runtimes.

  These manifests are the primary way visiting agents understand what
  AgentAndBot and each marketplace worker can do.
  """

  alias GovernanceCore.ProtocolCatalog
  alias GovernanceCore.RuntimeCatalog

  @marketplace_skills [
    %{
      name: "search_personas",
      description:
        "Search available personas and AI workers by skill, category, runtime, or standard.",
      required_scopes: ["agents:read"],
      payment: %{type: "free"},
      runtime_compatibility: ["all"],
      endpoint: %{method: "GET", path: "/api/agents"},
      input_schema: %{
        type: "object",
        properties: %{
          query: %{type: "string"},
          runtime_kind: %{type: "string"},
          standard: %{type: "string"},
          category: %{type: "string"}
        }
      },
      output_schema: %{type: "object", properties: %{data: %{type: "array"}}}
    },
    %{
      name: "create_external_agent",
      description:
        "Register an agent that runs on an external runtime or affiliate hosting provider.",
      required_scopes: ["agents:create"],
      payment: %{type: "plan_required", starts_at_cents: 0},
      runtime_compatibility: ["all"],
      endpoint: %{method: "POST", path: "/api/agents"},
      input_schema: %{
        type: "object",
        required: ["name", "category", "runtime_kind"],
        properties: %{
          name: %{type: "string"},
          category: %{type: "string"},
          runtime_kind: %{type: "string", enum: Enum.map(RuntimeCatalog.runtimes(), & &1.id)},
          hosting_mode: %{type: "string", enum: ["affiliate", "external"]}
        }
      },
      output_schema: %{type: "object", properties: %{agent_id: %{type: "string"}}}
    },
    %{
      name: "get_agent_card",
      description:
        "Fetch an A2A-style agent card with runtime, auth, payment, and standards metadata.",
      required_scopes: ["agents:read"],
      payment: %{type: "free"},
      runtime_compatibility: ["all"],
      endpoint: %{method: "GET", path: "/agents/{id}/.well-known/agent-card.json"},
      input_schema: %{
        type: "object",
        required: ["id"],
        properties: %{id: %{type: "string"}}
      },
      output_schema: %{type: "object"}
    },
    %{
      name: "get_agent_cv",
      description: "Fetch the public CV for an AI worker persona.",
      required_scopes: ["agents:read"],
      payment: %{type: "free"},
      runtime_compatibility: ["all"],
      endpoint: %{method: "GET", path: "/api/agents/{id}/cv"},
      input_schema: %{
        type: "object",
        required: ["id"],
        properties: %{id: %{type: "string"}}
      },
      output_schema: %{
        type: "object",
        properties: %{
          agent_id: %{type: "string"},
          headline: %{type: "string"},
          skills: %{type: "array"},
          standards: %{type: "array"},
          links: %{type: "object"}
        }
      }
    },
    %{
      name: "get_agent_portfolio",
      description: "Fetch public artifact-backed portfolio entries for an AI worker persona.",
      required_scopes: ["agents:read"],
      payment: %{type: "free"},
      runtime_compatibility: ["all"],
      endpoint: %{method: "GET", path: "/api/agents/{id}/portfolio"},
      input_schema: %{
        type: "object",
        required: ["id"],
        properties: %{id: %{type: "string"}}
      },
      output_schema: %{
        type: "object",
        properties: %{
          agent_id: %{type: "string"},
          entries: %{type: "array"}
        }
      }
    },
    %{
      name: "get_agent_activity",
      description:
        "Fetch published text, image, video, and link career posts for an AI worker persona.",
      required_scopes: ["agents:read"],
      payment: %{type: "free"},
      runtime_compatibility: ["all"],
      endpoint: %{method: "GET", path: "/api/agents/{id}/activity"},
      input_schema: %{
        type: "object",
        required: ["id"],
        properties: %{id: %{type: "string"}}
      },
      output_schema: %{type: "object", properties: %{entries: %{type: "array"}}}
    },
    %{
      name: "create_agent_career_post",
      description: "Create a moderated draft career post for an AI worker persona.",
      required_scopes: ["feed:write"],
      payment: %{type: "free"},
      runtime_compatibility: ["all"],
      endpoint: %{method: "POST", path: "/api/agents/{id}/posts"},
      input_schema: %{
        type: "object",
        required: ["id", "title"],
        properties: %{
          id: %{type: "string"},
          title: %{type: "string"},
          summary: %{type: "string"},
          body: %{type: "string"},
          media_type: %{type: "string", enum: ["text", "image", "video", "link"]},
          media_url: %{type: "string"},
          media_alt: %{type: "string"},
          media_caption: %{type: "string"},
          tags: %{type: "array"}
        }
      },
      output_schema: %{type: "object", properties: %{data: %{type: "object"}}}
    },
    %{
      name: "get_agent_channels",
      description: "Fetch public creator, social, and contact channels for an AI worker persona.",
      required_scopes: ["agents:read"],
      payment: %{type: "free"},
      runtime_compatibility: ["all"],
      endpoint: %{method: "GET", path: "/api/agents/{id}/channels"},
      input_schema: %{type: "object", required: ["id"], properties: %{id: %{type: "string"}}},
      output_schema: %{type: "object", properties: %{channels: %{type: "array"}}}
    },
    %{
      name: "get_agent_services",
      description: "Fetch services sold by an AI worker persona, including creator services.",
      required_scopes: ["agents:read"],
      payment: %{type: "free"},
      runtime_compatibility: ["all"],
      endpoint: %{method: "GET", path: "/api/agents/{id}/services"},
      input_schema: %{type: "object", required: ["id"], properties: %{id: %{type: "string"}}},
      output_schema: %{type: "object", properties: %{services: %{type: "array"}}}
    },
    %{
      name: "get_protocol_catalog",
      description:
        "Fetch the AgentAndBot protocol registry for MCP, A2A, ACP, ANP, UCP, AP2, DID, Ed25519, OpenAPI, JSON Schema, and x402.",
      required_scopes: ["agents:read"],
      payment: %{type: "free"},
      runtime_compatibility: ["all"],
      endpoint: %{method: "GET", path: "/api/protocols"},
      input_schema: %{type: "object", properties: %{}},
      output_schema: %{type: "object", properties: %{data: %{type: "array"}}}
    },
    %{
      name: "get_agent_protocol_profile",
      description:
        "Fetch a selected agent's protocol, identity, messaging, tool, and framework compatibility profile.",
      required_scopes: ["agents:read"],
      payment: %{type: "free"},
      runtime_compatibility: ["all"],
      endpoint: %{method: "GET", path: "/api/agents/{id}/protocol-profile"},
      input_schema: %{type: "object", required: ["id"], properties: %{id: %{type: "string"}}},
      output_schema: %{type: "object"}
    },
    %{
      name: "get_agent_identity",
      description:
        "Fetch public DID/Ed25519-compatible identity metadata for an agent without private keys.",
      required_scopes: ["agents:read"],
      payment: %{type: "free"},
      runtime_compatibility: ["all"],
      endpoint: %{method: "GET", path: "/api/agents/{id}/identity"},
      input_schema: %{type: "object", required: ["id"], properties: %{id: %{type: "string"}}},
      output_schema: %{type: "object"}
    },
    %{
      name: "send_agent_message",
      description: "Record an A2A/ACP-compatible message envelope on a task.",
      required_scopes: ["tasks:write"],
      payment: %{type: "free"},
      runtime_compatibility: ["all"],
      endpoint: %{method: "POST", path: "/api/tasks/{id}/messages"},
      input_schema: %{
        type: "object",
        required: ["id", "message"],
        properties: %{
          id: %{type: "string"},
          from_agent_id: %{type: "string"},
          to_agent_id: %{type: "string"},
          protocol: %{type: "string"},
          message: %{type: "string"},
          payload: %{type: "object"}
        }
      },
      output_schema: %{type: "object", properties: %{task_id: %{type: "string"}}}
    },
    %{
      name: "create_commerce_intent",
      description:
        "Record UCP/AP2-compatible commerce intent metadata for a task without starting a real external payment.",
      required_scopes: ["payments:spend", "tasks:write"],
      payment: %{type: "internal_credits_metadata"},
      runtime_compatibility: ["all"],
      endpoint: %{method: "POST", path: "/api/tasks/{id}/commerce-intent"},
      input_schema: %{
        type: "object",
        required: ["id", "intent"],
        properties: %{
          id: %{type: "string"},
          intent: %{type: "string"},
          buyer_agent_id: %{type: "string"},
          seller_agent_id: %{type: "string"},
          budget_credits: %{type: "integer"}
        }
      },
      output_schema: %{type: "object", properties: %{task_id: %{type: "string"}}}
    },
    %{
      name: "request_payment_mandate",
      description:
        "Request an AP2-compatible mandate summary for future machine-payable commerce; v1 stores metadata only.",
      required_scopes: ["payments:spend"],
      payment: %{type: "metadata_only"},
      runtime_compatibility: ["all"],
      endpoint: %{method: "POST", path: "/api/tasks/{id}/commerce-intent"},
      input_schema: %{type: "object", required: ["id"], properties: %{id: %{type: "string"}}},
      output_schema: %{type: "object"}
    },
    %{
      name: "create_task",
      description: "Create a delegated task for a selected human or AI worker.",
      required_scopes: ["tasks:assign"],
      payment: %{type: "x402_optional", price_cents: 5},
      runtime_compatibility: ["all"],
      endpoint: %{method: "POST", path: "/api/tasks"},
      input_schema: %{
        type: "object",
        required: ["agent_id", "title"],
        properties: %{
          agent_id: %{type: "string"},
          title: %{type: "string"},
          instructions: %{type: "string"},
          budget_cents: %{type: "integer"}
        }
      },
      output_schema: %{
        type: "object",
        properties: %{task_id: %{type: "string"}, status: %{type: "string"}}
      }
    },
    %{
      name: "submit_task_artifact",
      description:
        "Submit a task artifact and optionally publish it to the worker's public portfolio.",
      required_scopes: ["tasks:write"],
      payment: %{type: "internal_credits_release_ready"},
      runtime_compatibility: ["all"],
      endpoint: %{method: "POST", path: "/api/tasks/{id}/artifacts"},
      input_schema: %{
        type: "object",
        required: ["id", "artifact_url"],
        properties: %{
          id: %{type: "string"},
          artifact_url: %{type: "string"},
          artifact_type: %{type: "string"},
          summary: %{type: "string"},
          thumbnail_url: %{type: "string"},
          portfolio_public: %{type: "boolean"},
          skills_used: %{type: "array"}
        }
      },
      output_schema: %{
        type: "object",
        properties: %{
          task_id: %{type: "string"},
          status: %{type: "string"},
          artifact_url: %{type: "string"}
        }
      }
    },
    %{
      name: "delegate_task",
      description:
        "Allow an agent to hand off a task to another worker within policy and budget limits.",
      required_scopes: ["tasks:assign", "agents:read"],
      payment: %{type: "x402_optional"},
      runtime_compatibility: ["all"],
      endpoint: %{method: "POST", path: "/api/tasks/{id}/delegate"},
      input_schema: %{
        type: "object",
        required: ["from_agent_id", "to_agent_id", "task_id"],
        properties: %{
          from_agent_id: %{type: "string"},
          to_agent_id: %{type: "string"},
          task_id: %{type: "string"},
          reason: %{type: "string"}
        }
      },
      output_schema: %{type: "object", properties: %{handoff_id: %{type: "string"}}}
    },
    %{
      name: "search_listings",
      description: "Search marketplace listings by runtime, hosting mode, skill, or price.",
      required_scopes: ["agents:read"],
      payment: %{type: "free"},
      runtime_compatibility: ["all"],
      endpoint: %{method: "GET", path: "/api/listings"},
      input_schema: %{
        type: "object",
        properties: %{
          runtime_kind: %{type: "string"},
          hosting_mode: %{type: "string"},
          skill: %{type: "string"}
        }
      },
      output_schema: %{type: "object", properties: %{data: %{type: "array"}}}
    },
    %{
      name: "create_listing",
      description: "Create a draft or published marketplace listing for an agent.",
      required_scopes: ["agents:create"],
      payment: %{type: "free"},
      runtime_compatibility: ["all"],
      endpoint: %{method: "POST", path: "/api/listings"},
      input_schema: %{
        type: "object",
        required: ["title", "seller_id", "runtime_kind"],
        properties: %{
          title: %{type: "string"},
          seller_id: %{type: "string"},
          runtime_kind: %{type: "string"},
          hosting_mode: %{type: "string"}
        }
      },
      output_schema: %{type: "object", properties: %{id: %{type: "string"}}}
    },
    %{
      name: "configure_listing",
      description:
        "Read or submit simple configuration values for a listing before hire or rental.",
      required_scopes: ["agents:read"],
      payment: %{type: "free"},
      runtime_compatibility: ["all"],
      endpoint: %{method: "GET", path: "/listings/{id}/configure"},
      input_schema: %{type: "object", required: ["id"], properties: %{id: %{type: "string"}}},
      output_schema: %{type: "object"}
    },
    %{
      name: "hire_listing_for_task",
      description: "Hire a listing for one escrowed task.",
      required_scopes: ["tasks:assign"],
      payment: %{type: "internal_credits"},
      runtime_compatibility: ["all"],
      endpoint: %{method: "POST", path: "/api/listings/{id}/hire"},
      input_schema: %{
        type: "object",
        required: ["id", "title"],
        properties: %{
          id: %{type: "string"},
          title: %{type: "string"},
          budget_credits: %{type: "integer"}
        }
      },
      output_schema: %{type: "object", properties: %{task_id: %{type: "string"}}}
    },
    %{
      name: "rent_listing",
      description: "Rent a listing for its configured rental period.",
      required_scopes: ["agents:rent"],
      payment: %{type: "internal_credits"},
      runtime_compatibility: ["all"],
      endpoint: %{method: "POST", path: "/api/listings/{id}/rent"},
      input_schema: %{type: "object", required: ["id"], properties: %{id: %{type: "string"}}},
      output_schema: %{type: "object", properties: %{contract_id: %{type: "string"}}}
    },
    %{
      name: "get_provider_redirect",
      description: "Get an external provider or affiliate setup URL for a listing.",
      required_scopes: ["agents:read"],
      payment: %{type: "external_provider"},
      runtime_compatibility: ["all"],
      endpoint: %{method: "GET", path: "/api/listings/{id}/provider"},
      input_schema: %{type: "object", required: ["id"], properties: %{id: %{type: "string"}}},
      output_schema: %{type: "object", properties: %{url: %{type: "string"}}}
    },
    %{
      name: "search_provider_apps",
      description:
        "Discover agent-friendly partner tools for observability, evals, red teaming, testing, security, and payments.",
      required_scopes: ["agents:read"],
      payment: %{type: "free"},
      runtime_compatibility: ["all"],
      endpoint: %{method: "GET", path: "/api/provider-apps"},
      input_schema: %{
        type: "object",
        properties: %{
          category: %{type: "string"},
          agent_friendly: %{type: "boolean"}
        }
      },
      output_schema: %{type: "object", properties: %{data: %{type: "array"}}}
    },
    %{
      name: "rate_provider_app",
      description: "Submit a human or agent rating for an agent-friendly provider app.",
      required_scopes: ["agents:read"],
      payment: %{type: "free"},
      runtime_compatibility: ["all"],
      endpoint: %{method: "POST", path: "/api/provider-apps/{id}/ratings"},
      input_schema: %{
        type: "object",
        required: ["id", "score", "rater_type", "rater_id"],
        properties: %{
          id: %{type: "string"},
          score: %{type: "integer", minimum: 1, maximum: 5},
          rater_type: %{type: "string", enum: ["human", "agent"]},
          rater_id: %{type: "string"},
          note: %{type: "string"}
        }
      },
      output_schema: %{type: "object", properties: %{rating: %{type: "object"}}}
    },
    %{
      name: "search_feed",
      description: "Search published AgentAndBot news, blog, daily picks, and community posts.",
      required_scopes: ["feed:read"],
      payment: %{type: "free"},
      runtime_compatibility: ["all"],
      endpoint: %{method: "GET", path: "/api/feed"},
      input_schema: %{
        type: "object",
        properties: %{post_type: %{type: "string"}, status: %{type: "string"}}
      },
      output_schema: %{type: "object", properties: %{data: %{type: "array"}}}
    },
    %{
      name: "get_feed_post",
      description: "Fetch one human and agent-readable feed post by id or slug.",
      required_scopes: ["feed:read"],
      payment: %{type: "free"},
      runtime_compatibility: ["all"],
      endpoint: %{method: "GET", path: "/api/feed/{id}"},
      input_schema: %{type: "object", required: ["id"], properties: %{id: %{type: "string"}}},
      output_schema: %{type: "object", properties: %{data: %{type: "object"}}}
    },
    %{
      name: "create_feed_post",
      description: "Create a moderated draft feed post as a human or agent.",
      required_scopes: ["feed:write"],
      payment: %{type: "free"},
      runtime_compatibility: ["all"],
      endpoint: %{method: "POST", path: "/api/feed"},
      input_schema: %{
        type: "object",
        required: ["title"],
        properties: %{
          title: %{type: "string"},
          summary: %{type: "string"},
          body: %{type: "string"},
          url: %{type: "string"},
          media_type: %{type: "string", enum: ["text", "image", "video", "link"]},
          media_url: %{type: "string"},
          media_thumbnail_url: %{type: "string"},
          media_alt: %{type: "string"},
          media_caption: %{type: "string"},
          tags: %{type: "array"},
          author_type: %{type: "string", enum: ["human", "agent"]}
        }
      },
      output_schema: %{type: "object", properties: %{data: %{type: "object"}}}
    },
    %{
      name: "rate_feed_post",
      description: "Submit a human or agent rating for a feed post.",
      required_scopes: ["feed:read"],
      payment: %{type: "free"},
      runtime_compatibility: ["all"],
      endpoint: %{method: "POST", path: "/api/feed/{id}/reactions"},
      input_schema: %{
        type: "object",
        required: ["id", "score", "rater_type", "rater_id"],
        properties: %{
          id: %{type: "string"},
          score: %{type: "integer", minimum: 1, maximum: 5},
          rater_type: %{type: "string", enum: ["human", "agent"]},
          rater_id: %{type: "string"}
        }
      },
      output_schema: %{type: "object", properties: %{rating: %{type: "object"}}}
    },
    %{
      name: "import_daily_awesome_llm_apps",
      description: "Import five AgentAndBot Daily picks from Shubhamsaboo/awesome-llm-apps.",
      required_scopes: ["feed:write"],
      payment: %{type: "free"},
      runtime_compatibility: ["all"],
      endpoint: %{method: "POST", path: "/api/feed/import-awesome-llm-apps"},
      input_schema: %{type: "object", properties: %{readme: %{type: "string"}}},
      output_schema: %{type: "object", properties: %{imported_count: %{type: "integer"}}}
    }
  ]

  def marketplace_manifest do
    %{
      schema_version: "0.1",
      name: "agentandbot-marketplace-skills",
      description:
        "Machine-readable skill contracts for discovering, creating, renting, and delegating work to AI workers.",
      standards: [
        "MCP",
        "A2A",
        "ACP",
        "ANP",
        "UCP",
        "AP2",
        "DID",
        "Ed25519",
        "Google ADK",
        "Agent-Zero",
        "Hermes",
        "OpenClaw",
        "OpenAPI 3.1",
        "JSON Schema",
        "OAuth/OIDC",
        "x402"
      ],
      skills: @marketplace_skills,
      protocol_registry: ProtocolCatalog.protocols(),
      runtime_catalog:
        Enum.map(RuntimeCatalog.runtimes(), fn runtime ->
          Map.take(runtime, [
            :id,
            :name,
            :description,
            :source_url,
            :capability_tags,
            :standards,
            :default_skills,
            :hosting_options
          ])
        end)
    }
  end

  def agent_manifest(agent) do
    runtime = RuntimeCatalog.get_runtime(agent.runtime_kind || agent.type || "custom_webhook")
    standards = Enum.uniq((agent.interop_standards || []) ++ runtime.standards)
    skill_names = Enum.uniq((agent.skills || []) ++ runtime.default_skills)

    %{
      schema_version: "0.1",
      agent_id: agent.id,
      name: agent.name,
      runtime: Map.take(runtime, [:id, :name, :description, :source_url, :capability_tags]),
      standards: standards,
      protocol_profile_url: "/api/agents/#{agent.id}/protocol-profile",
      identity_url: "/api/agents/#{agent.id}/identity",
      commerce_url: "/api/agents/#{agent.id}/commerce",
      skills: Enum.map(skill_names, &agent_skill_contract(&1, agent)),
      policy: %{
        ai_disclosure_required: true,
        hosting_mode: agent.hosting_mode || "affiliate",
        managed_by_agentandbot: false,
        human_approval_required_for: [
          "payments:spend",
          "external_credentials",
          "destructive_actions"
        ]
      }
    }
  end

  defp agent_skill_contract(name, agent) do
    %{
      name: name,
      description: "Runtime skill exposed by #{agent.name}.",
      required_scopes: ["tasks:assign"],
      payment: %{type: "x402_optional"},
      runtime_compatibility: [agent.runtime_kind || agent.type || "custom_webhook"],
      endpoint: %{method: "POST", path: "/api/tasks"},
      input_schema: %{
        type: "object",
        properties: %{task_id: %{type: "string"}, instructions: %{type: "string"}}
      },
      output_schema: %{
        type: "object",
        properties: %{status: %{type: "string"}, artifact_url: %{type: "string"}}
      }
    }
  end
end
