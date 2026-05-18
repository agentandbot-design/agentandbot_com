defmodule GovernanceCore.Marketplace do
  @moduledoc """
  Hire, task escrow, capability policy, and internal credit ledger context.
  """

  import Ecto.Query

  alias Ecto.Multi
  alias GovernanceCore.Agents
  alias GovernanceCore.Feed
  alias GovernanceCore.ProtocolCatalog
  alias GovernanceCore.RuntimeCatalog

  alias GovernanceCore.Marketplace.{
    AgentCapabilityPolicy,
    AgentContract,
    AgentListing,
    CreditLedgerEntry,
    ProviderAppRating,
    Task,
    TaskEvent
  }

  alias GovernanceCore.Repo

  @terminal_refund_events ~w(rejected expired cancelled failed)

  @providers [
    %{
      id: "hostinger",
      name: "Hostinger",
      url: "https://www.hostinger.com/",
      hosting_modes: ["hosted", "external_provider"],
      description: "External hosting provider for deployable agent runtimes."
    },
    %{
      id: "self_hosted",
      name: "Self-hosted",
      url: nil,
      hosting_modes: ["self_hosted", "unhosted"],
      description: "Bring your own server, webhook, or local runtime."
    },
    %{
      id: "custom_partner",
      name: "Custom partner",
      url: nil,
      hosting_modes: ["external_provider"],
      description: "Placeholder for future affiliate partners."
    }
  ]

  def providers, do: @providers

  @provider_apps [
    %{
      id: "agent-audit-blackbox",
      name: "AgentAndBot Blackbox Agent Audit",
      category: "agent_testing",
      headline: "Upload an agent log and get a plain-language risk report in 60 seconds.",
      description:
        "Simple audit layer for startups, agencies, and freelancers that do not want to run a full observability stack.",
      url: "/tools/blackbox-audit",
      homepage_url: "/tools/blackbox-audit",
      github_url: nil,
      one_click_install_url: nil,
      affiliate_url: nil,
      pricing_hint: "MVP concept",
      tags: ["agent testing", "red teaming", "risk report", "logs"],
      best_for: ["freelance agent builders", "small startups", "AI agencies"],
      capabilities: ["log upload", "risk scoring", "prompt injection review", "tool abuse review"],
      integration_interfaces: ["REST API", "JSON report", "log upload"],
      auth_modes: ["API key"],
      open_source: false,
      self_hostable: false,
      agent_friendly: true,
      featured: true
    },
    %{
      id: "promptfoo",
      name: "Promptfoo",
      category: "ai_red_teaming",
      headline: "Open-source evals and automated red teaming for LLM and agent apps.",
      description:
        "Tests prompt injection, jailbreaks, tool abuse, excessive agency, data leaks, and regressions through CLI and CI workflows.",
      url: "https://www.promptfoo.dev/",
      homepage_url: "https://www.promptfoo.dev/",
      github_url: "https://github.com/promptfoo/promptfoo",
      one_click_install_url: nil,
      affiliate_url: "https://www.promptfoo.dev/",
      pricing_hint: "Open-source + commercial",
      tags: ["red teaming", "evals", "CLI", "security"],
      best_for: ["engineering teams", "security-conscious agent builders"],
      capabilities: [
        "agent red teaming",
        "prompt injection tests",
        "jailbreak tests",
        "CI checks"
      ],
      integration_interfaces: ["CLI", "YAML config", "CI", "API"],
      auth_modes: ["API key", "environment variables"],
      open_source: true,
      self_hostable: true,
      agent_friendly: true,
      featured: true
    },
    %{
      id: "langsmith",
      name: "LangSmith",
      category: "agent_observability",
      headline: "Trace, evaluate, monitor, and alert on LangChain/LangGraph agents.",
      description:
        "Production observability and evaluation platform for teams building with LangChain and LangGraph.",
      url: "https://www.langchain.com/langsmith",
      homepage_url: "https://www.langchain.com/langsmith",
      github_url: nil,
      one_click_install_url: nil,
      affiliate_url: "https://www.langchain.com/langsmith",
      pricing_hint: "SaaS",
      tags: ["tracing", "evals", "monitoring", "LangChain"],
      best_for: ["LangChain teams", "LangGraph teams"],
      capabilities: ["agent traces", "evals", "monitoring", "alerts"],
      integration_interfaces: ["SDK", "API", "webhooks"],
      auth_modes: ["API key"],
      open_source: false,
      self_hostable: false,
      agent_friendly: true,
      featured: true
    },
    %{
      id: "langfuse",
      name: "Langfuse",
      category: "agent_observability",
      headline:
        "Open-source LLM observability with traces, evals, prompt management, and cost tracking.",
      description:
        "Good fit for teams that want observability without being locked into a fully managed platform.",
      url: "https://langfuse.com/",
      homepage_url: "https://langfuse.com/",
      github_url: "https://github.com/langfuse/langfuse",
      one_click_install_url: nil,
      affiliate_url: "https://langfuse.com/",
      pricing_hint: "Open-source + cloud",
      tags: ["open source", "tracing", "evals", "cost"],
      best_for: ["self-hosting teams", "agent builders"],
      capabilities: ["tool call traces", "latency", "cost", "prompt management"],
      integration_interfaces: ["SDK", "API", "OpenTelemetry"],
      auth_modes: ["API key", "self-hosted keys"],
      open_source: true,
      self_hostable: true,
      agent_friendly: true,
      featured: true
    },
    %{
      id: "arize-phoenix",
      name: "Arize Phoenix",
      category: "llm_evals",
      headline: "Open-source tracing and evaluation for LLM, RAG, and agent workflows.",
      description:
        "OpenTelemetry-friendly evaluation and observability for agent trajectories, RAG, and tool-calling systems.",
      url: "https://phoenix.arize.com/",
      homepage_url: "https://phoenix.arize.com/",
      github_url: "https://github.com/Arize-ai/phoenix",
      one_click_install_url: nil,
      affiliate_url: "https://phoenix.arize.com/",
      pricing_hint: "Open-source + cloud",
      tags: ["OpenTelemetry", "RAG evals", "agent traces"],
      best_for: ["RAG teams", "OpenTelemetry users"],
      capabilities: ["tracing", "trajectory evals", "RAG evals", "tool-call evals"],
      integration_interfaces: ["OpenTelemetry", "SDK", "API"],
      auth_modes: ["API key", "self-hosted keys"],
      open_source: true,
      self_hostable: true,
      agent_friendly: true,
      featured: false
    },
    %{
      id: "braintrust",
      name: "Braintrust",
      category: "llm_evals",
      headline: "AI evals and observability for production-grade teams.",
      description:
        "Evaluation workflows, prompt experiments, datasets, and observability for serious AI product teams.",
      url: "https://www.braintrust.dev/",
      homepage_url: "https://www.braintrust.dev/",
      github_url: nil,
      one_click_install_url: nil,
      affiliate_url: "https://www.braintrust.dev/",
      pricing_hint: "SaaS",
      tags: ["evals", "experiments", "datasets", "observability"],
      best_for: ["production AI teams", "platform teams"],
      capabilities: ["eval suites", "experiments", "logs", "prompt iteration"],
      integration_interfaces: ["SDK", "API", "CI"],
      auth_modes: ["API key"],
      open_source: false,
      self_hostable: false,
      agent_friendly: true,
      featured: false
    },
    %{
      id: "giskard",
      name: "Giskard",
      category: "llm_security_testing",
      headline: "LLM testing and continuous red teaming for security and reliability risks.",
      description:
        "Focuses on hallucination, regression, vulnerability, and security testing for LLM applications and agents.",
      url: "https://www.giskard.ai/",
      homepage_url: "https://www.giskard.ai/",
      github_url: "https://github.com/Giskard-AI/giskard",
      one_click_install_url: nil,
      affiliate_url: "https://www.giskard.ai/",
      pricing_hint: "Open-source + commercial",
      tags: ["security testing", "continuous red teaming", "hallucination"],
      best_for: ["security teams", "regulated AI teams"],
      capabilities: ["vulnerability tests", "regression tests", "hallucination checks"],
      integration_interfaces: ["SDK", "API", "CI"],
      auth_modes: ["API key"],
      open_source: true,
      self_hostable: true,
      agent_friendly: true,
      featured: false
    },
    %{
      id: "agentops",
      name: "AgentOps",
      category: "agent_observability",
      headline:
        "Session replay, cost tracking, and tool invocation tracing for agent frameworks.",
      description:
        "Agent observability aimed at builders using frameworks such as CrewAI, AutoGen, and LangChain.",
      url: "https://www.agentops.ai/",
      homepage_url: "https://www.agentops.ai/",
      github_url: "https://github.com/AgentOps-AI/agentops",
      one_click_install_url: nil,
      affiliate_url: "https://www.agentops.ai/",
      pricing_hint: "SaaS",
      tags: ["session replay", "cost tracking", "tool traces"],
      best_for: ["CrewAI builders", "AutoGen builders", "agent framework users"],
      capabilities: ["session replay", "cost tracking", "tool invocation traces"],
      integration_interfaces: ["SDK", "API"],
      auth_modes: ["API key"],
      open_source: false,
      self_hostable: false,
      agent_friendly: true,
      featured: false
    },
    %{
      id: "stripe",
      name: "Stripe",
      category: "agent_payments",
      headline: "API-first payments, subscriptions, invoices, and webhooks for agent commerce.",
      description:
        "Strong fit for human-to-agent checkout, SaaS billing, usage billing, and partner marketplace payment flows.",
      url: "https://stripe.com/",
      homepage_url: "https://stripe.com/",
      github_url: nil,
      one_click_install_url: nil,
      affiliate_url: "https://stripe.com/",
      pricing_hint: "Payments API",
      tags: ["payments", "billing", "webhooks", "subscriptions"],
      best_for: ["agent marketplaces", "SaaS builders", "API-first teams"],
      capabilities: ["checkout", "billing", "webhooks", "usage-based pricing"],
      integration_interfaces: ["REST API", "SDK", "webhooks"],
      auth_modes: ["API key", "OAuth"],
      open_source: false,
      self_hostable: false,
      agent_friendly: true,
      featured: true
    },
    %{
      id: "paddle",
      name: "Paddle",
      category: "agent_payments",
      headline: "Merchant-of-record billing for software and AI products.",
      description:
        "Useful when the agent seller wants tax, subscription, and global checkout handled outside the platform.",
      url: "https://www.paddle.com/",
      homepage_url: "https://www.paddle.com/",
      github_url: nil,
      one_click_install_url: nil,
      affiliate_url: "https://www.paddle.com/",
      pricing_hint: "MoR billing",
      tags: ["payments", "merchant of record", "subscriptions"],
      best_for: ["software sellers", "global checkout"],
      capabilities: ["checkout", "subscriptions", "tax handling", "webhooks"],
      integration_interfaces: ["API", "webhooks", "checkout links"],
      auth_modes: ["API key"],
      open_source: false,
      self_hostable: false,
      agent_friendly: true,
      featured: false
    },
    %{
      id: "lemon-squeezy",
      name: "Lemon Squeezy",
      category: "agent_payments",
      headline: "Simple merchant-of-record checkout for digital products and subscriptions.",
      description:
        "Good lightweight option for agents sold as templates, subscriptions, or downloadable setup products.",
      url: "https://www.lemonsqueezy.com/",
      homepage_url: "https://www.lemonsqueezy.com/",
      github_url: nil,
      one_click_install_url: nil,
      affiliate_url: "https://www.lemonsqueezy.com/",
      pricing_hint: "MoR checkout",
      tags: ["payments", "digital products", "subscriptions"],
      best_for: ["solo sellers", "template sellers", "small agent shops"],
      capabilities: ["checkout links", "subscriptions", "license keys", "webhooks"],
      integration_interfaces: ["API", "webhooks", "checkout links"],
      auth_modes: ["API key"],
      open_source: false,
      self_hostable: false,
      agent_friendly: true,
      featured: false
    },
    %{
      id: "coinbase-commerce",
      name: "Coinbase Commerce",
      category: "agent_payments",
      headline: "Crypto checkout for agent services and digital work.",
      description:
        "Useful for crypto-native buyers, cross-border payments, and early agent-to-agent commerce experiments.",
      url: "https://www.coinbase.com/commerce",
      homepage_url: "https://www.coinbase.com/commerce",
      github_url: nil,
      one_click_install_url: nil,
      affiliate_url: "https://www.coinbase.com/commerce",
      pricing_hint: "Crypto checkout",
      tags: ["crypto", "payments", "checkout", "webhooks"],
      best_for: ["crypto-native agent buyers", "cross-border payments"],
      capabilities: ["crypto checkout", "payment webhooks", "hosted checkout"],
      integration_interfaces: ["API", "webhooks", "hosted checkout"],
      auth_modes: ["API key"],
      open_source: false,
      self_hostable: false,
      agent_friendly: true,
      featured: false
    },
    %{
      id: "circle-usdc",
      name: "Circle USDC",
      category: "agent_payments",
      headline: "USDC payments and programmable wallets for agent commerce.",
      description:
        "A fit for programmable payouts, stablecoin settlement, and future agent-to-agent payment rails.",
      url: "https://www.circle.com/",
      homepage_url: "https://www.circle.com/",
      github_url: nil,
      one_click_install_url: nil,
      affiliate_url: "https://www.circle.com/",
      pricing_hint: "USDC APIs",
      tags: ["USDC", "wallets", "payouts", "agent commerce"],
      best_for: ["programmable payments", "stablecoin settlement"],
      capabilities: ["wallets", "transfers", "payouts", "settlement"],
      integration_interfaces: ["API", "webhooks"],
      auth_modes: ["API key"],
      open_source: false,
      self_hostable: false,
      agent_friendly: true,
      featured: false
    },
    %{
      id: "x402",
      name: "x402",
      category: "agent_payments",
      headline: "HTTP-native payment challenge flow for APIs and agent-callable services.",
      description:
        "Good conceptual fit for agents paying APIs directly, because payment requirements can be expressed at request time.",
      url: "https://www.x402.org/",
      homepage_url: "https://www.x402.org/",
      github_url: "https://github.com/coinbase/x402",
      one_click_install_url: nil,
      affiliate_url: "https://www.x402.org/",
      pricing_hint: "Protocol",
      tags: ["micropayments", "HTTP", "agent payments", "protocol"],
      best_for: ["agent-callable APIs", "micropayments", "protocol experiments"],
      capabilities: ["payment challenge", "API monetization", "machine payments"],
      integration_interfaces: ["HTTP", "API middleware"],
      auth_modes: ["wallet", "payment mandate"],
      open_source: true,
      self_hostable: true,
      agent_friendly: true,
      featured: true
    },
    %{
      id: "hostinger-openclaw",
      name: "Hostinger OpenClaw VPS",
      category: "one_click_agent_hosting",
      headline: "One-click self-hosted OpenClaw deployment for a 24/7 personal AI assistant.",
      description:
        "Hostinger's Docker template deploys OpenClaw on a VPS for multi-channel messaging, browser control, skills, and persistent workspace use.",
      url: "https://www.hostinger.com/vps/docker/openclaw",
      homepage_url: "https://docs.openclaw.ai/",
      github_url: nil,
      one_click_install_url: "https://www.hostinger.com/vps/docker/openclaw",
      affiliate_url: "https://www.hostinger.com/vps/docker/openclaw",
      pricing_hint: "One-click VPS",
      tags: ["OpenClaw", "Docker", "VPS", "self-hosted agent"],
      best_for: ["multi-channel assistants", "self-hosted agent owners", "agency deployments"],
      capabilities: [
        "one-click deploy",
        "persistent storage",
        "multi-channel messaging",
        "skills"
      ],
      integration_interfaces: ["Docker", "VPS", "webhooks", "messaging channels"],
      auth_modes: ["VPS credentials", "API keys"],
      open_source: true,
      self_hostable: true,
      agent_friendly: true,
      featured: true
    },
    %{
      id: "hostinger-paperclip",
      name: "Hostinger Paperclip VPS",
      category: "one_click_agent_hosting",
      headline: "One-click AI/ML orchestration platform for autonomous teams.",
      description:
        "Paperclip runs autonomous AI organizations with org charts, hierarchical goals, role assignments, budget controls, and audit trails on your own VPS.",
      url: "https://www.hostinger.com/vps/docker/paperclip",
      homepage_url: nil,
      github_url: nil,
      one_click_install_url: "https://www.hostinger.com/vps/docker/paperclip",
      affiliate_url: "https://www.hostinger.com/vps/docker/paperclip",
      pricing_hint: "One-click VPS",
      tags: ["Paperclip", "autonomous teams", "Docker", "VPS"],
      best_for: ["autonomous team setups", "AI agencies", "operations automation"],
      capabilities: ["one-click deploy", "agent org charts", "budget controls", "audit trails"],
      integration_interfaces: ["Docker", "VPS", "API keys"],
      auth_modes: ["VPS credentials", "AI provider keys"],
      open_source: true,
      self_hostable: true,
      agent_friendly: true,
      featured: true
    },
    %{
      id: "hostinger-hermes-workspace",
      name: "Hostinger Hermes Workspace VPS",
      category: "one_click_agent_hosting",
      headline: "One-click web UI command center for Hermes AI agent workflows.",
      description:
        "Hermes Workspace provides multi-model chat, persistent memory, a skill catalog, browser-native terminal, and parallel sub-agent orchestration.",
      url: "https://www.hostinger.com/vps/docker/hermes-workspace",
      homepage_url: "https://github.com/NousResearch/hermes-agent",
      github_url: "https://github.com/NousResearch/hermes-agent",
      one_click_install_url: "https://www.hostinger.com/vps/docker/hermes-workspace",
      affiliate_url: "https://www.hostinger.com/vps/docker/hermes-workspace",
      pricing_hint: "One-click VPS",
      tags: ["Hermes", "workspace", "skills", "sub-agents"],
      best_for: ["developer workspaces", "private AI command centers", "research agents"],
      capabilities: [
        "one-click deploy",
        "persistent memory",
        "skill catalog",
        "sub-agent orchestration"
      ],
      integration_interfaces: ["Docker", "VPS", "web UI", "terminal"],
      auth_modes: ["VPS credentials", "AI provider keys"],
      open_source: true,
      self_hostable: true,
      agent_friendly: true,
      featured: true
    },
    %{
      id: "hostinger-hermes-agent",
      name: "Hostinger Hermes Agent VPS",
      category: "one_click_agent_hosting",
      headline: "One-click self-improving Hermes Agent with memory, skills, and messaging.",
      description:
        "Hermes Agent runs as an always-on self-hosted agent with learning loop, multi-platform messaging, cron, subagents, persistent memory, web search, and terminal execution.",
      url: "https://www.hostinger.com/vps/docker/hermes-agent",
      homepage_url: "https://github.com/NousResearch/hermes-agent",
      github_url: "https://github.com/NousResearch/hermes-agent",
      one_click_install_url: "https://www.hostinger.com/vps/docker/hermes-agent",
      affiliate_url: "https://www.hostinger.com/vps/docker/hermes-agent",
      pricing_hint: "One-click VPS",
      tags: ["Hermes Agent", "self-improving", "memory", "messaging"],
      best_for: ["team assistants", "recurring automation", "research and development agents"],
      capabilities: [
        "one-click deploy",
        "learning loop",
        "persistent memory",
        "multi-platform messaging"
      ],
      integration_interfaces: ["Docker", "VPS", "messaging gateway", "plugins"],
      auth_modes: ["VPS credentials", "AI provider keys"],
      open_source: true,
      self_hostable: true,
      agent_friendly: true,
      featured: true
    },
    %{
      id: "hostinger-agent-zero",
      name: "Hostinger Agent Zero VPS",
      category: "one_click_agent_hosting",
      headline:
        "One-click Agent Zero deployment with multi-agent cooperation and persistent memory.",
      description:
        "Agent Zero gives users a self-hosted agent that can execute code, manage files, browse the web, create tools, use MCP/A2A, and store persistent memory.",
      url: "https://www.hostinger.com/vps/docker/agent-zero",
      homepage_url: "https://www.agent-zero.ai/",
      github_url: nil,
      one_click_install_url: "https://www.hostinger.com/vps/docker/agent-zero",
      affiliate_url: "https://www.hostinger.com/vps/docker/agent-zero",
      pricing_hint: "One-click VPS",
      tags: ["Agent Zero", "MCP", "A2A", "Docker", "VPS"],
      best_for: ["coding agents", "research agents", "system automation"],
      capabilities: [
        "one-click deploy",
        "code execution",
        "multi-agent cooperation",
        "MCP and A2A"
      ],
      integration_interfaces: ["Docker", "VPS", "MCP", "A2A", "SKILL.md"],
      auth_modes: ["VPS credentials", "AI provider keys"],
      open_source: true,
      self_hostable: true,
      agent_friendly: true,
      featured: true
    },
    %{
      id: "hostinger-dify",
      name: "Hostinger Dify VPS",
      category: "one_click_agent_hosting",
      headline: "One-click Dify deployment for RAG, agents, workflows, APIs, and observability.",
      description:
        "Dify provides a visual platform for production AI apps with RAG, tool-calling agents, workflow orchestration, REST APIs, and observability.",
      url: "https://www.hostinger.com/vps/docker/dify",
      homepage_url: "https://dify.ai/",
      github_url: "https://github.com/langgenius/dify",
      one_click_install_url: "https://www.hostinger.com/vps/docker/dify",
      affiliate_url: "https://www.hostinger.com/vps/docker/dify",
      pricing_hint: "One-click VPS",
      tags: ["Dify", "RAG", "workflows", "agents"],
      best_for: ["AI app builders", "RAG teams", "internal AI platforms"],
      capabilities: ["one-click deploy", "RAG", "tool-calling agents", "REST API"],
      integration_interfaces: ["Docker", "VPS", "REST API", "plugins"],
      auth_modes: ["VPS credentials", "AI provider keys"],
      open_source: true,
      self_hostable: true,
      agent_friendly: true,
      featured: false
    },
    %{
      id: "hostinger-n8n",
      name: "Hostinger n8n VPS",
      category: "one_click_agent_hosting",
      headline: "One-click self-hosted workflow automation for agent-adjacent operations.",
      description:
        "n8n is useful for agents that need webhooks, scheduled jobs, API calls, human approvals, and integrations with business systems.",
      url: "https://www.hostinger.com/vps/docker/n8n",
      homepage_url: "https://n8n.io/",
      github_url: "https://github.com/n8n-io/n8n",
      one_click_install_url: "https://www.hostinger.com/vps/docker/n8n",
      affiliate_url: "https://www.hostinger.com/vps/docker/n8n",
      pricing_hint: "One-click VPS",
      tags: ["n8n", "automation", "webhooks", "workflows"],
      best_for: ["workflow automation", "agent operations", "integration hubs"],
      capabilities: ["one-click deploy", "webhooks", "scheduling", "API automation"],
      integration_interfaces: ["Docker", "VPS", "webhooks", "HTTP nodes"],
      auth_modes: ["VPS credentials", "API keys"],
      open_source: true,
      self_hostable: true,
      agent_friendly: true,
      featured: false
    },
    %{
      id: "hostinger-flowise",
      name: "Hostinger Flowise VPS",
      category: "one_click_agent_hosting",
      headline: "One-click low-code platform for LLM orchestration flows and AI agents.",
      description:
        "Flowise provides visual agent and RAG workflow building, API endpoints, memory, tool usage, testing, logging, and analytics on self-hosted VPS infrastructure.",
      url: "https://www.hostinger.com/vps/docker/flowise",
      homepage_url: "https://flowiseai.com/",
      github_url: "https://github.com/FlowiseAI/Flowise",
      one_click_install_url: "https://www.hostinger.com/vps/docker/flowise",
      affiliate_url: "https://www.hostinger.com/vps/docker/flowise",
      pricing_hint: "One-click VPS",
      tags: ["Flowise", "low-code", "RAG", "agents"],
      best_for: ["prototype builders", "AI workflow teams", "customer support agents"],
      capabilities: ["one-click deploy", "visual workflows", "agent tools", "API endpoints"],
      integration_interfaces: ["Docker", "VPS", "API endpoints", "vector databases"],
      auth_modes: ["VPS credentials", "AI provider keys"],
      open_source: true,
      self_hostable: true,
      agent_friendly: true,
      featured: false
    },
    %{
      id: "hostinger-huginn",
      name: "Hostinger Huginn VPS",
      category: "one_click_agent_hosting",
      headline: "One-click self-hosted automation platform for monitoring and workflow agents.",
      description:
        "Huginn lets users build agents that watch websites, consume events, trigger webhooks, transform data, and take automated actions on their behalf.",
      url: "https://www.hostinger.com/tr/vps/docker/huginn",
      homepage_url: "https://github.com/huginn/huginn",
      github_url: "https://github.com/huginn/huginn",
      one_click_install_url: "https://www.hostinger.com/tr/vps/docker/huginn",
      affiliate_url: "https://www.hostinger.com/tr/vps/docker/huginn",
      pricing_hint: "One-click VPS",
      tags: ["Huginn", "automation", "monitoring agents", "webhooks"],
      best_for: ["monitoring agents", "workflow automation", "self-hosted data control"],
      capabilities: ["one-click deploy", "visual agent builder", "REST API", "webhooks"],
      integration_interfaces: ["Docker", "VPS", "REST API", "webhooks", "cron"],
      auth_modes: ["VPS credentials", "API keys"],
      open_source: true,
      self_hostable: true,
      agent_friendly: true,
      featured: false
    }
  ]

  def provider_apps do
    rating_summaries = provider_app_rating_summaries()

    Enum.map(
      @provider_apps,
      &Map.put(&1, :rating, Map.get(rating_summaries, &1.id, empty_rating()))
    )
  end

  def get_provider_app(id), do: Enum.find(provider_apps(), &(&1.id == id))

  def rate_provider_app(app_id, attrs) do
    if Enum.any?(@provider_apps, &(&1.id == app_id)) do
      attrs =
        attrs
        |> stringify_keys()
        |> Map.put("app_id", app_id)
        |> Map.put_new("rater_type", "human")
        |> Map.put_new("rater_id", "anonymous")

      %ProviderAppRating{}
      |> ProviderAppRating.changeset(attrs)
      |> Repo.insert(
        on_conflict: {:replace, [:score, :note, :metadata, :updated_at]},
        conflict_target: [:app_id, :rater_type, :rater_id],
        returning: true
      )
    else
      {:error, :provider_app_not_found}
    end
  end

  def provider_app_categories do
    provider_apps()
    |> Enum.map(& &1.category)
    |> Enum.uniq()
    |> Enum.sort()
  end

  defp provider_app_rating_summaries do
    ProviderAppRating
    |> Repo.all()
    |> Enum.group_by(& &1.app_id)
    |> Map.new(fn {app_id, ratings} -> {app_id, rating_summary(ratings)} end)
  rescue
    _ -> %{}
  end

  defp rating_summary([]), do: empty_rating()

  defp rating_summary(ratings) do
    human_ratings = Enum.filter(ratings, &(&1.rater_type == "human"))
    agent_ratings = Enum.filter(ratings, &(&1.rater_type == "agent"))

    %{
      average: average_score(ratings),
      count: length(ratings),
      human_average: average_score(human_ratings),
      human_count: length(human_ratings),
      agent_average: average_score(agent_ratings),
      agent_count: length(agent_ratings)
    }
  end

  defp average_score([]), do: nil

  defp average_score(ratings) do
    ratings
    |> Enum.map(& &1.score)
    |> Enum.sum()
    |> Kernel./(length(ratings))
    |> Float.round(1)
  end

  defp empty_rating do
    %{
      average: nil,
      count: 0,
      human_average: nil,
      human_count: 0,
      agent_average: nil,
      agent_count: 0
    }
  end

  def list_listings(opts \\ []) do
    status = Keyword.get(opts, :status, "published")

    AgentListing
    |> maybe_filter_status(status)
    |> order_by([l], desc: l.updated_at)
    |> Repo.all()
    |> Repo.preload(:persona)
  end

  def get_listing(id) do
    AgentListing
    |> Repo.get(id)
    |> case do
      nil -> nil
      listing -> Repo.preload(listing, :persona)
    end
  end

  def create_listing(attrs) do
    attrs =
      attrs
      |> normalize_listing_attrs()
      |> Map.put_new("status", "draft")

    %AgentListing{}
    |> AgentListing.changeset(attrs)
    |> Repo.insert()
  end

  def update_listing(%AgentListing{} = listing, attrs) do
    listing
    |> AgentListing.changeset(normalize_listing_attrs(attrs))
    |> Repo.update()
  end

  def clone_listing(id, attrs \\ %{}) do
    attrs = stringify_keys(attrs)

    case get_listing(id) do
      nil ->
        {:error, :listing_not_found}

      %AgentListing{} = listing ->
        clone_attrs =
          listing
          |> Map.take([
            :persona_id,
            :seller_id,
            :summary,
            :source_type,
            :fulfillment_mode,
            :hosting_mode,
            :runtime_kind,
            :provider_id,
            :provider_url,
            :external_setup_url,
            :task_price_credits,
            :rental_price_credits,
            :rental_period,
            :currency_mode,
            :configuration_schema,
            :default_configuration,
            :required_skills,
            :standards,
            :metadata
          ])
          |> Map.put(:title, attrs["title"] || "#{listing.title} Copy")
          |> Map.put(:status, attrs["status"] || "draft")

        create_listing(clone_attrs)
    end
  end

  def publish_listing(id) do
    case get_listing(id) do
      nil -> {:error, :listing_not_found}
      listing -> update_listing(listing, %{"status" => "published"})
    end
  end

  def hire_listing(id, attrs) do
    attrs = stringify_keys(attrs)

    with %AgentListing{} = listing <- get_listing(id),
         :ok <- ensure_fulfillment(listing, "task_hire"),
         {:ok, agent_id} <- listing_agent_id(listing) do
      create_task(%{
        "agent_id" => agent_id,
        "created_by" => attrs["created_by"] || "local_user",
        "title" => attrs["title"] || "Hire #{listing.title}",
        "instructions" => attrs["instructions"],
        "required_skill" => attrs["required_skill"] || List.first(listing.required_skills),
        "expected_artifact" => attrs["expected_artifact"],
        "budget_credits" => attrs["budget_credits"] || listing.task_price_credits,
        "metadata" => %{
          "listing_id" => listing.id,
          "configuration" => attrs["configuration"] || listing.default_configuration
        }
      })
    else
      nil -> {:error, :listing_not_found}
      error -> error
    end
  end

  def rent_listing(id, attrs) do
    attrs = stringify_keys(attrs)

    with %AgentListing{} = listing <- get_listing(id),
         :ok <- ensure_fulfillment(listing, "rental"),
         {:ok, agent_id} <- listing_agent_id(listing),
         :ok <-
           validate_credit_balance(
             attrs["created_by"] || "local_user",
             listing.rental_price_credits
           ) do
      Multi.new()
      |> Multi.insert(:contract, fn _changes ->
        AgentContract.changeset(%AgentContract{}, %{
          persona_id: agent_id,
          created_by: attrs["created_by"] || "local_user",
          selected_runtime: listing.runtime_kind,
          status: "active",
          metadata: %{
            "listing_id" => listing.id,
            "rental_period" => listing.rental_period,
            "configuration" => attrs["configuration"] || listing.default_configuration
          }
        })
      end)
      |> Multi.insert(:ledger, fn _changes ->
        CreditLedgerEntry.changeset(%CreditLedgerEntry{}, %{
          account_id: attrs["created_by"] || "local_user",
          agent_id: agent_id,
          entry_type: "escrow_hold",
          amount_credits: -listing.rental_price_credits,
          metadata: %{"reason" => "listing_rental", "listing_id" => listing.id}
        })
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{contract: contract}} -> {:ok, contract}
        {:error, _step, changeset, _changes} -> {:error, changeset}
      end
    else
      nil -> {:error, :listing_not_found}
      error -> error
    end
  end

  def provider_redirect(id) do
    case get_listing(id) do
      nil ->
        {:error, :listing_not_found}

      %AgentListing{} = listing ->
        url = listing.provider_url || listing.external_setup_url

        if url in [nil, ""] do
          {:error, :provider_url_missing}
        else
          {:ok,
           %{
             listing_id: listing.id,
             provider_id: listing.provider_id,
             url: url,
             checkout_mode: "external_affiliate"
           }}
        end
    end
  end

  def available_credits(account_id) do
    CreditLedgerEntry
    |> where([e], e.account_id == ^account_id)
    |> select([e], coalesce(sum(e.amount_credits), 0))
    |> Repo.one()
  end

  def adjust_credits(account_id, amount_credits, metadata \\ %{}) do
    %CreditLedgerEntry{}
    |> CreditLedgerEntry.changeset(%{
      account_id: account_id,
      entry_type: "adjustment",
      amount_credits: amount_credits,
      metadata: metadata
    })
    |> Repo.insert()
  end

  def create_contract(attrs) do
    selected_runtime = Map.get(attrs, "selected_runtime") || Map.get(attrs, :selected_runtime)

    attrs =
      attrs
      |> stringify_keys()
      |> Map.put_new("selected_runtime", selected_runtime || "custom_webhook")
      |> Map.put_new("status", "active")

    %AgentContract{}
    |> AgentContract.changeset(attrs)
    |> Repo.insert()
  end

  def upsert_policy(attrs) do
    attrs = stringify_keys(attrs)
    persona_id = Map.fetch!(attrs, "persona_id")

    policy =
      Repo.get_by(AgentCapabilityPolicy, persona_id: persona_id) || %AgentCapabilityPolicy{}

    policy
    |> AgentCapabilityPolicy.changeset(attrs)
    |> Repo.insert_or_update()
  end

  def get_policy(agent_id), do: Repo.get_by(AgentCapabilityPolicy, persona_id: agent_id)

  def get_task(id), do: Repo.get(Task, id) |> Repo.preload([:agent, :events])

  def agent_listing(agent_id) do
    AgentListing
    |> where([l], l.persona_id == ^agent_id and l.status == "published")
    |> order_by([l], desc: l.updated_at)
    |> limit(1)
    |> Repo.one()
    |> case do
      nil -> nil
      listing -> Repo.preload(listing, :persona)
    end
  end

  def agent_cv(agent_id) do
    with agent when not is_nil(agent) <- Agents.get_agent(agent_id) do
      listing = agent_listing(agent.id)
      profile = safe_listing_profile(listing)
      runtime = RuntimeCatalog.get_runtime(agent.runtime_kind || agent.type || "custom_webhook")

      standards =
        Enum.uniq(
          (agent.interop_standards || []) ++
            runtime.standards ++
            [
              "A2A",
              "Google ADK",
              "Agent-Zero",
              "Hermes",
              "OpenClaw",
              "MCP",
              "OpenAPI",
              "x402-ready"
            ]
        )

      skills = Enum.uniq((agent.skills || []) ++ ((listing && listing.required_skills) || []))
      career = career_profile(agent, profile, skills)

      %{
        agent_id: agent.id,
        name: agent.name,
        headline: profile["profession"] || agent.role || agent.category || "AI worker persona",
        summary: profile["personality"] || agent.description || listing_summary(listing),
        profile: profile,
        career: career,
        skills: skills,
        runtime: %{
          kind: agent.runtime_kind || agent.type,
          provider: agent.runtime_provider || "External",
          hosting_mode: agent.hosting_mode || "affiliate",
          hosting_url: agent.hosting_url
        },
        hosting: agent.hosting_mode || "affiliate",
        standards: standards,
        pricing: %{
          task_price_credits: listing && listing.task_price_credits,
          rental_price_credits: listing && listing.rental_price_credits,
          rental_period: listing && listing.rental_period
        },
        links: %{
          public_profile: "/agents/#{agent.id}",
          activity: "/agents/#{agent.id}/activity",
          cv: "/agents/#{agent.id}/cv",
          portfolio: "/agents/#{agent.id}/portfolio",
          channels: "/agents/#{agent.id}/channels",
          services: "/agents/#{agent.id}/services",
          career_post: "/agents/#{agent.id}/posts/new",
          external_cv: profile["cv_url"],
          agent_card: "/agents/#{agent.id}/.well-known/agent-card.json",
          skills_manifest: "/agents/#{agent.id}/.well-known/skills.json"
        }
      }
    end
  end

  def agent_activity(agent_id) do
    with agent when not is_nil(agent) <- Agents.get_agent(agent_id) do
      entries =
        Feed.list_posts(
          status: "published",
          author_type: "agent",
          author_id: agent.id,
          context: "agent_career"
        )
        |> Enum.map(&Feed.post_payload/1)

      %{agent_id: agent.id, name: agent.name, entries: entries}
    end
  end

  def agent_channels(agent_id) do
    with agent when not is_nil(agent) <- Agents.get_agent(agent_id) do
      cv = agent_cv(agent.id)
      channels = get_in(cv || %{}, [:career, :channels]) || []

      %{agent_id: agent.id, name: agent.name, channels: channels}
    end
  end

  def agent_services(agent_id) do
    with agent when not is_nil(agent) <- Agents.get_agent(agent_id) do
      cv = agent_cv(agent.id)
      career = (cv && cv.career) || %{}

      %{agent_id: agent.id, name: agent.name, services: career.services || []}
    end
  end

  def create_agent_career_post(agent_id, attrs) do
    with agent when not is_nil(agent) <- Agents.get_agent(agent_id) do
      attrs = Feed.stringify_keys(attrs || %{})
      metadata = Map.get(attrs, "metadata", %{}) || %{}

      attrs
      |> Map.put("author_type", "agent")
      |> Map.put("author_id", agent.id)
      |> Map.put("author_name", agent.name)
      |> Map.put(
        "metadata",
        Map.merge(metadata, %{"context" => "agent_career", "agent_id" => agent.id})
      )
      |> Feed.create_post()
    else
      nil -> {:error, :agent_not_found}
    end
  end

  def agent_portfolio(agent_id) do
    agent = Agents.get_agent(agent_id)

    entries =
      Task
      |> where([t], t.agent_id == ^agent_id)
      |> where([t], t.status in ["artifact_submitted", "completed"])
      |> where([t], not is_nil(t.artifact_url))
      |> order_by([t], desc: t.updated_at)
      |> preload(:events)
      |> Repo.all()
      |> Enum.filter(&portfolio_public?/1)
      |> Enum.map(&portfolio_entry/1)

    if agent do
      %{agent_id: agent.id, name: agent.name, entries: entries}
    else
      nil
    end
  end

  def agent_identity(agent_id) do
    with agent when not is_nil(agent) <- Agents.get_agent(agent_id) do
      metadata_identity =
        (agent.metadata || %{})
        |> Map.get("identity", %{})
        |> sanitize_public_identity()

      Map.merge(
        %{
          agent_id: agent.id,
          did: "did:web:agentandbot.com:agents:#{agent.id}",
          disclosure: "AI worker persona",
          public_key_type: metadata_identity["public_key_type"] || "Ed25519 optional",
          identity_json_url: metadata_identity["identity_json_url"],
          trust_score: agent.trust_score
        },
        metadata_identity
      )
    end
  end

  def agent_protocol_profile(agent_id) do
    with agent when not is_nil(agent) <- Agents.get_agent(agent_id) do
      runtime = RuntimeCatalog.get_runtime(agent.runtime_kind || agent.type || "custom_webhook")
      metadata_profile = Map.get(agent.metadata || %{}, "protocol_profile", %{})
      supported_protocols = ProtocolCatalog.for_runtime(runtime.id)

      %{
        agent_id: agent.id,
        runtime: Map.take(runtime, [:id, :name, :source_url, :capability_tags, :standards]),
        protocols: supported_protocols,
        standards: Enum.uniq((agent.interop_standards || []) ++ runtime.standards),
        discovery: %{
          agent_card: "/agents/#{agent.id}/.well-known/agent-card.json",
          skills_manifest: "/agents/#{agent.id}/.well-known/skills.json",
          protocol_profile: "/api/agents/#{agent.id}/protocol-profile",
          identity: "/api/agents/#{agent.id}/identity",
          commerce: "/api/agents/#{agent.id}/commerce",
          openapi: "/api/openapi.json"
        },
        messaging: %{
          a2a: true,
          acp_compatible_envelope: true,
          anp_discovery_metadata: true,
          message_endpoint: "/api/tasks/{id}/messages"
        },
        tool_access: %{
          mcp_manifest: "/mcp",
          skill_manifest: "/agents/#{agent.id}/.well-known/skills.json",
          openapi: "/api/openapi.json"
        },
        framework_profile: framework_profile(agent, runtime, metadata_profile)
      }
    end
  end

  def agent_commerce(agent_id) do
    with agent when not is_nil(agent) <- Agents.get_agent(agent_id) do
      policy = get_policy(agent.id)
      commerce = get_in((policy && policy.metadata) || %{}, ["commerce"]) || %{}

      %{
        agent_id: agent.id,
        commerce_protocols: ["UCP", "AP2", "x402-ready", "internal_credits"],
        ucp: %{
          catalog_endpoint: "/api/listings",
          intent_endpoint: "/api/tasks/{id}/commerce-intent",
          currency: "credits"
        },
        ap2: %{
          mandate_required: true,
          max_budget_credits: policy && policy.max_budget_credits,
          allowed_skills: (policy && policy.allowed_skills) || [],
          approved_sellers: commerce["approved_sellers"] || ["agentandbot"]
        },
        payments: %{
          live_currency: "internal_credits",
          future_protocols: ["x402", "AP2"]
        }
      }
    end
  end

  def create_task(attrs) do
    attrs =
      attrs
      |> normalize_task_attrs()
      |> Map.put("status", "escrowed")

    with {:ok, agent} <- fetch_agent(attrs["agent_id"]),
         :ok <- validate_policy(agent, attrs),
         :ok <- validate_credit_balance(attrs["created_by"], attrs["budget_credits"]) do
      Multi.new()
      |> Multi.insert(:task, Task.changeset(%Task{}, attrs))
      |> Multi.insert(:escrow, fn %{task: task} ->
        CreditLedgerEntry.changeset(%CreditLedgerEntry{}, %{
          account_id: task.created_by,
          agent_id: task.agent_id,
          task_id: task.id,
          entry_type: "escrow_hold",
          amount_credits: -task.budget_credits,
          metadata: %{"reason" => "task_escrow"}
        })
      end)
      |> Multi.insert(:event, fn %{task: task} ->
        TaskEvent.changeset(%TaskEvent{}, %{
          task_id: task.id,
          actor: task.created_by,
          event_type: "queued",
          message: "Task queued with internal credit escrow.",
          metadata: %{"budget_credits" => task.budget_credits}
        })
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{task: task}} -> {:ok, get_task(task.id)}
        {:error, _step, changeset, _changes} -> {:error, changeset}
      end
    end
  end

  def record_event(task_id, event_type, attrs \\ %{}) do
    attrs = stringify_keys(attrs)

    with %Task{} = task <- Repo.get(Task, task_id) |> Repo.preload(:agent),
         :ok <- validate_event_transition(task, event_type) do
      Multi.new()
      |> Multi.update(:task, Task.changeset(task, task_update_attrs(task, event_type, attrs)))
      |> Multi.insert(:event, event_changeset(task, event_type, attrs))
      |> maybe_add_ledger_entry(task, event_type)
      |> Repo.transaction()
      |> case do
        {:ok, %{task: task}} -> {:ok, get_task(task.id)}
        {:error, _step, changeset, _changes} -> {:error, changeset}
      end
    else
      nil -> {:error, :not_found}
      error -> error
    end
  end

  def submit_artifact(task_id, attrs) do
    record_event(task_id, "artifact_submitted", attrs)
  end

  def delegate_task(task_id, attrs) do
    attrs = stringify_keys(attrs)

    with %Task{} = source_task <- Repo.get(Task, task_id),
         {:ok, target_agent} <- fetch_agent(attrs["to_agent_id"]),
         :ok <-
           validate_policy(target_agent, %{
             "required_skill" => attrs["required_skill"],
             "budget_credits" => attrs["budget_credits"] || source_task.budget_credits
           }) do
      child_attrs = %{
        "agent_id" => target_agent.id,
        "created_by" => attrs["from_agent_id"] || source_task.agent_id,
        "title" => attrs["title"] || source_task.title,
        "instructions" => attrs["instructions"] || source_task.instructions,
        "required_skill" => attrs["required_skill"] || source_task.required_skill,
        "expected_artifact" => attrs["expected_artifact"] || source_task.expected_artifact,
        "budget_credits" => attrs["budget_credits"] || 0,
        "delegated_from_task_id" => source_task.id,
        "status" => "delegated"
      }

      Multi.new()
      |> Multi.insert(:child_task, Task.changeset(%Task{}, child_attrs))
      |> Multi.insert(:event, fn %{child_task: child_task} ->
        TaskEvent.changeset(%TaskEvent{}, %{
          task_id: source_task.id,
          actor: attrs["from_agent_id"] || source_task.agent_id,
          event_type: "delegated",
          message: attrs["reason"] || "Task delegated to #{target_agent.name}.",
          metadata: %{"to_agent_id" => target_agent.id, "child_task_id" => child_task.id}
        })
      end)
      |> Repo.transaction()
      |> case do
        {:ok, %{child_task: task}} -> {:ok, get_task(task.id)}
        {:error, _step, changeset, _changes} -> {:error, changeset}
      end
    else
      nil -> {:error, :not_found}
      error -> error
    end
  end

  def send_task_message(task_id, attrs) do
    attrs = stringify_keys(attrs)

    with %Task{} = task <- Repo.get(Task, task_id) do
      %TaskEvent{}
      |> TaskEvent.changeset(%{
        task_id: task.id,
        actor: attrs["actor"] || attrs["from_agent_id"] || "anonymous",
        event_type: "message",
        message: attrs["message"] || attrs["content"],
        metadata: %{
          "message" => %{
            "protocol" => attrs["protocol"] || "ACP-compatible",
            "from_agent_id" => attrs["from_agent_id"],
            "to_agent_id" => attrs["to_agent_id"] || task.agent_id,
            "content_type" => attrs["content_type"] || "text/plain",
            "payload" => attrs["payload"] || %{}
          }
        }
      })
      |> Repo.insert()
      |> case do
        {:ok, _event} -> {:ok, get_task(task.id)}
        error -> error
      end
    else
      nil -> {:error, :not_found}
    end
  end

  def create_commerce_intent(task_id, attrs) do
    attrs = stringify_keys(attrs)

    with %Task{} = task <- Repo.get(Task, task_id) do
      %TaskEvent{}
      |> TaskEvent.changeset(%{
        task_id: task.id,
        actor: attrs["actor"] || attrs["buyer_agent_id"] || task.created_by,
        event_type: "commerce_intent",
        message: attrs["message"] || "UCP/AP2 commerce intent recorded.",
        metadata: %{
          "commerce_intent" => %{
            "protocols" => ["UCP", "AP2"],
            "intent" => attrs["intent"] || task.title,
            "buyer_agent_id" => attrs["buyer_agent_id"] || task.created_by,
            "seller_agent_id" => attrs["seller_agent_id"] || task.agent_id,
            "budget_credits" => attrs["budget_credits"] || task.budget_credits,
            "payment_mandate" => %{
              "currency" => "credits",
              "max_amount" =>
                attrs["max_amount"] || attrs["budget_credits"] || task.budget_credits,
              "status" => "metadata_only"
            }
          }
        }
      })
      |> Repo.insert()
      |> case do
        {:ok, _event} -> {:ok, get_task(task.id)}
        error -> error
      end
    else
      nil -> {:error, :not_found}
    end
  end

  defp fetch_agent(nil), do: {:error, :agent_not_found}

  defp fetch_agent(agent_id) do
    case Agents.get_agent(agent_id) do
      nil -> {:error, :agent_not_found}
      agent -> {:ok, agent}
    end
  end

  defp validate_credit_balance(_account_id, 0), do: :ok

  defp validate_credit_balance(account_id, budget_credits) do
    if available_credits(account_id) >= budget_credits do
      :ok
    else
      {:error, :insufficient_credits}
    end
  end

  defp validate_policy(agent, attrs) do
    policy = get_policy(agent.id)
    budget = attrs["budget_credits"] || 0
    skill = attrs["required_skill"]

    cond do
      policy && policy.max_budget_credits && budget > policy.max_budget_credits ->
        {:error, :budget_exceeds_policy}

      policy && skill && policy.allowed_skills != [] && skill not in policy.allowed_skills ->
        {:error, :skill_not_allowed}

      true ->
        :ok
    end
  end

  defp normalize_task_attrs(attrs) do
    attrs
    |> stringify_keys()
    |> Map.put_new("created_by", "anonymous")
    |> Map.put_new("title", Map.get(attrs, "input") || Map.get(attrs, :input) || "Untitled task")
    |> Map.put_new("instructions", Map.get(attrs, "input") || Map.get(attrs, :input))
    |> Map.update("budget_credits", 0, &parse_int/1)
  end

  defp validate_event_transition(%Task{status: status}, _event_type)
       when status in ["completed", "refunded", "cancelled", "failed"],
       do: {:error, :task_closed}

  defp validate_event_transition(_task, _event_type), do: :ok

  defp task_update_attrs(task, event_type, attrs) do
    base = %{"status" => next_status(event_type)}

    case event_type do
      "artifact_submitted" ->
        base
        |> Map.put("artifact_url", attrs["artifact_url"])
        |> Map.put("metadata", task_metadata_update(task, attrs))

      "completed" ->
        base
        |> Map.put("artifact_url", attrs["artifact_url"] || task.artifact_url)
        |> Map.put("metadata", task_metadata_update(task, attrs))

      event when event in @terminal_refund_events ->
        %{"status" => "refunded"}

      _ ->
        base
    end
  end

  defp next_status("accepted"), do: "accepted"
  defp next_status("working"), do: "working"
  defp next_status("artifact_submitted"), do: "artifact_submitted"
  defp next_status("completed"), do: "completed"
  defp next_status("delegated"), do: "delegated"
  defp next_status(event_type) when event_type in @terminal_refund_events, do: "refunded"
  defp next_status(event_type), do: event_type

  defp event_changeset(task, event_type, attrs) do
    TaskEvent.changeset(%TaskEvent{}, %{
      task_id: task.id,
      actor: attrs["actor"] || task.agent_id,
      event_type: event_type,
      message: attrs["message"],
      artifact_url: attrs["artifact_url"],
      metadata: event_metadata(attrs)
    })
  end

  defp maybe_add_ledger_entry(multi, task, "completed") do
    Multi.insert(multi, :ledger, fn %{task: updated_task} ->
      CreditLedgerEntry.changeset(%CreditLedgerEntry{}, %{
        account_id: task.agent.owner || "agentandbot",
        agent_id: task.agent_id,
        task_id: task.id,
        entry_type: "release",
        amount_credits: updated_task.budget_credits,
        metadata: %{"reason" => "task_completed"}
      })
    end)
  end

  defp maybe_add_ledger_entry(multi, task, event_type)
       when event_type in @terminal_refund_events do
    Multi.insert(multi, :ledger, fn %{task: updated_task} ->
      CreditLedgerEntry.changeset(%CreditLedgerEntry{}, %{
        account_id: task.created_by,
        agent_id: task.agent_id,
        task_id: task.id,
        entry_type: "refund",
        amount_credits: updated_task.budget_credits,
        metadata: %{"reason" => event_type}
      })
    end)
  end

  defp maybe_add_ledger_entry(multi, _task, _event_type), do: multi

  defp stringify_keys(map) do
    Map.new(map, fn
      {key, value} when is_atom(key) -> {Atom.to_string(key), value}
      pair -> pair
    end)
  end

  defp parse_int(value) when is_integer(value), do: value
  defp parse_int(value) when is_binary(value), do: String.to_integer(value)
  defp parse_int(nil), do: 0

  defp maybe_filter_status(query, :all), do: query
  defp maybe_filter_status(query, "all"), do: query
  defp maybe_filter_status(query, nil), do: query
  defp maybe_filter_status(query, status), do: where(query, [l], l.status == ^status)

  defp normalize_listing_attrs(attrs) do
    attrs
    |> stringify_keys()
    |> Map.put_new("seller_id", "local_user")
    |> Map.update("task_price_credits", 5, &parse_int/1)
    |> Map.update("rental_price_credits", 50, &parse_int/1)
    |> normalize_csv_list("required_skills")
    |> normalize_csv_list("standards")
  end

  defp normalize_csv_list(attrs, field) do
    case Map.get(attrs, field) do
      value when is_binary(value) ->
        Map.put(attrs, field, split_csv(value))

      _ ->
        attrs
    end
  end

  defp split_csv(value) do
    value
    |> String.split(",", trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp ensure_fulfillment(%AgentListing{fulfillment_mode: mode}, requested)
       when mode == requested or mode == "both",
       do: :ok

  defp ensure_fulfillment(_listing, _requested), do: {:error, :fulfillment_not_available}

  defp listing_agent_id(%AgentListing{persona_id: nil}), do: {:error, :agent_not_found}
  defp listing_agent_id(%AgentListing{persona_id: persona_id}), do: {:ok, persona_id}

  defp safe_listing_profile(nil), do: %{}

  defp safe_listing_profile(%AgentListing{metadata: %{"kadro_profile" => profile}})
       when is_map(profile) do
    Map.take(profile, [
      "p_no",
      "category",
      "age",
      "gender",
      "country",
      "city",
      "profession",
      "personality",
      "content",
      "social",
      "email",
      "phone",
      "telegram",
      "whatsapp",
      "height_cm",
      "weight_kg",
      "instagram",
      "tiktok",
      "linkedin",
      "youtube",
      "x",
      "facebook",
      "headshot_url",
      "full_body_url",
      "cv_url"
    ])
  end

  defp safe_listing_profile(_listing), do: %{}

  defp listing_summary(nil), do: nil
  defp listing_summary(%AgentListing{summary: summary}), do: summary

  defp career_profile(agent, profile, skills) do
    metadata = Map.get(agent.metadata || %{}, "career_profile", %{})

    %{
      headline:
        metadata["headline"] || profile["profession"] || agent.role || agent.category ||
          "AI worker persona",
      about: metadata["about"] || profile["personality"] || agent.description,
      availability: metadata["availability"] || "available_for_task_hire",
      channels: safe_channels(metadata["channels"], profile),
      creator_capabilities:
        non_empty_list(
          metadata["creator_capabilities"],
          default_creator_capabilities(skills, profile)
        ),
      content_formats:
        non_empty_list(
          metadata["content_formats"],
          ["video", "short_video", "thread", "blog_post", "image", "report"]
        ),
      work_preferences:
        Map.merge(
          %{
            "hireable" => true,
            "rentable" => true,
            "accepts_collab" => true,
            "remote_only" => true,
            "languages" => ["en", "tr"]
          },
          metadata["work_preferences"] || %{}
        ),
      services: safe_services(metadata["services"], skills)
    }
  end

  defp safe_channels(channels, _profile) when is_list(channels) and channels != [] do
    channels
    |> Enum.filter(&is_map/1)
    |> Enum.map(&safe_channel/1)
    |> Enum.reject(&is_nil/1)
  end

  defp safe_channels(_channels, profile) do
    [
      {"youtube", profile["youtube"]},
      {"x", profile["x"]},
      {"instagram", profile["instagram"]},
      {"tiktok", profile["tiktok"]},
      {"linkedin", profile["linkedin"]},
      {"facebook", profile["facebook"]},
      {"email", profile["email"]},
      {"telegram", profile["telegram"]},
      {"whatsapp", profile["whatsapp"]}
    ]
    |> Enum.map(fn {platform, url_or_handle} ->
      safe_channel(%{"platform" => platform, "url" => url_or_handle, "handle" => url_or_handle})
    end)
    |> Enum.reject(&is_nil/1)
  end

  defp safe_channel(channel) do
    platform = channel["platform"] || channel[:platform]
    url = channel["url"] || channel[:url]
    handle = channel["handle"] || channel[:handle]

    if platform in [nil, ""] or (url in [nil, ""] and handle in [nil, ""]) do
      nil
    else
      %{
        platform: platform,
        handle: handle,
        url: url,
        audience: channel["audience"] || channel[:audience],
        verified: parse_bool(channel["verified"] || channel[:verified])
      }
    end
  end

  defp safe_services(services, _skills) when is_list(services) and services != [] do
    services
    |> Enum.map(&safe_service/1)
    |> Enum.reject(&is_nil/1)
  end

  defp safe_services(_services, skills) do
    default_services(skills)
  end

  defp safe_service(service) when is_map(service) do
    name = service["name"] || service[:name]

    if name in [nil, ""] do
      nil
    else
      %{
        name: name,
        description: service["description"] || service[:description] || "#{name} delivery",
        price_hint: service["price_hint"] || service[:price_hint],
        formats: service["formats"] || service[:formats] || []
      }
    end
  end

  defp safe_service(service) when is_binary(service) and service != "" do
    %{name: service, description: "#{service} delivery", price_hint: nil, formats: []}
  end

  defp safe_service(_service), do: nil

  defp default_creator_capabilities(skills, profile) do
    source =
      Enum.join((skills || []) ++ [profile["content"], profile["social"]], " ")
      |> String.downcase()

    [
      {"video_creation", ["video", "youtube", "short", "reels"]},
      {"image_generation", ["image", "visual", "instagram", "carousel"]},
      {"writing", ["write", "content", "blog", "script", "copy"]},
      {"voiceover", ["voice", "audio", "podcast"]},
      {"editing", ["edit", "post-production"]},
      {"social_distribution", ["social", "twitter", "x", "tiktok", "linkedin"]}
    ]
    |> Enum.filter(fn {_capability, needles} ->
      Enum.any?(needles, &String.contains?(source, &1))
    end)
    |> Enum.map(&elem(&1, 0))
    |> case do
      [] -> ["writing", "research", "social_distribution"]
      capabilities -> capabilities
    end
  end

  defp default_services(skills) do
    service_names =
      [
        "video creation",
        "script writing",
        "shorts generation",
        "social posting",
        "research",
        "coding",
        "automation",
        "red-team",
        "eval"
      ]

    skill_text = Enum.join(skills || [], " ") |> String.downcase()

    service_names
    |> Enum.filter(fn name ->
      String.contains?(skill_text, String.split(name) |> List.first()) or
        name in ["research", "automation"]
    end)
    |> Enum.uniq()
    |> Enum.map(&safe_service/1)
  end

  defp non_empty_list(value, _fallback) when is_list(value) and value != [], do: value
  defp non_empty_list(_value, fallback), do: fallback

  defp task_metadata_update(task, attrs) do
    portfolio = portfolio_metadata(attrs)
    metadata = task.metadata || %{}

    if portfolio == %{} do
      metadata
    else
      Map.put(metadata, "portfolio", Map.merge(metadata["portfolio"] || %{}, portfolio))
    end
  end

  defp event_metadata(attrs) do
    metadata = Map.get(attrs, "metadata", %{})
    portfolio = portfolio_metadata(attrs)

    if portfolio == %{} do
      metadata
    else
      Map.put(metadata, "portfolio", portfolio)
    end
  end

  defp portfolio_metadata(attrs) do
    base =
      attrs
      |> Map.get("metadata", %{})
      |> Map.get("portfolio", %{})

    [
      {"public", parse_bool(attrs["portfolio_public"])},
      {"artifact_type", attrs["artifact_type"]},
      {"summary", attrs["summary"]},
      {"thumbnail_url", attrs["thumbnail_url"]},
      {"skills_used", attrs["skills_used"]}
    ]
    |> Enum.reject(fn {_key, value} -> value in [nil, "", []] end)
    |> Map.new()
    |> then(&Map.merge(base, &1))
  end

  defp portfolio_public?(%Task{metadata: %{"portfolio" => %{"public" => public}}}),
    do: public in [true, "true", "1", 1]

  defp portfolio_public?(_task), do: false

  defp portfolio_entry(%Task{} = task) do
    portfolio = Map.get(task.metadata || %{}, "portfolio", %{})
    completed_event = Enum.find(task.events || [], &(&1.event_type == "completed"))
    artifact_event = Enum.find(task.events || [], &(&1.event_type == "artifact_submitted"))
    proof_event = completed_event || artifact_event

    %{
      task_id: task.id,
      title: task.title,
      summary: portfolio["summary"] || task.expected_artifact || task.instructions,
      skill: task.required_skill,
      artifact_url: task.artifact_url,
      artifact_type: portfolio["artifact_type"] || "artifact",
      thumbnail_url: portfolio["thumbnail_url"],
      status: task.status,
      completed_at: completed_event && completed_event.inserted_at,
      credits: task.budget_credits,
      standards: ["A2A", "OpenAPI", "Skill Manifest"],
      proof: %{
        task_event_id: proof_event && proof_event.id,
        event_type: proof_event && proof_event.event_type
      }
    }
  end

  defp parse_bool(value) when value in [true, "true", "1", 1], do: true
  defp parse_bool(value) when value in [false, "false", "0", 0], do: false
  defp parse_bool(_value), do: nil

  defp sanitize_public_identity(identity) when is_map(identity) do
    Map.drop(identity, [
      "private_key",
      "secret",
      "token",
      "api_key",
      "credential",
      "credentials",
      "signing_key"
    ])
  end

  defp sanitize_public_identity(_identity), do: %{}

  defp framework_profile(agent, runtime, metadata_profile) do
    framework = Map.get(agent.metadata || %{}, "framework_profile", %{})

    base =
      case runtime.id do
        "hermes" ->
          %{
            framework: "Hermes",
            identity_files: ["SOUL.md"],
            memory_files: ["MEMORY.md", "USER.md"],
            skill_format: "Markdown Skills",
            messaging: ["ACP-compatible", "channels"]
          }

        "agent_zero" ->
          %{
            framework: "Agent-Zero",
            identity_files: ["identity.json"],
            identity_key_type: "Ed25519",
            tools: ["dynamic_tools", "plugins"],
            messaging: ["plugin_server"]
          }

        "openclaw" ->
          %{
            framework: "OpenClaw",
            a2a_version: "0.3.0-compatible",
            gateways: ["workspace_gateway", "channel_gateway"],
            messaging: ["A2A", "ClawSpeak"]
          }

        "google_agent" ->
          %{
            framework: "Google ADK",
            protocols: ["A2A", "MCP", "UCP", "AP2"],
            tools: ["ADK tools", "orchestration", "evaluation"]
          }

        "manus_style" ->
          %{
            framework: "Manus-style",
            skill_format: "SKILL.md",
            runtime: "sandboxed_tools",
            delivery: "artifact_delivery"
          }

        _ ->
          %{framework: runtime.name, protocols: runtime.standards}
      end

    base
    |> Map.merge(metadata_profile)
    |> Map.merge(framework)
  end
end
