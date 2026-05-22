defmodule GovernanceCore.PublicServices do
  @moduledoc """
  Public-callable services that may run under e-any.online and be consumed by other sites.
  """

  alias GovernanceCore.InternalTools
  alias GovernanceCore.Payment.Payments

  @cv_generator %{
    name: "CV Generator",
    slug: "cv-generator",
    owner_wallet: "0x34691456184C0CcD9E5c18A9E383637651aA146F",
    endpoint_url: "https://cv.e-any.online/api/generate",
    price_per_request: 25,
    active: true
  }

  def cv_generator, do: @cv_generator

  def cv_generator_internal_tool do
    %{
      slug: "cv-generator",
      name: "CV Generator",
      url: "https://cv.e-any.online/",
      container_name: "cv-generator",
      category: "public_service",
      owner: "product",
      audience: ["external_sites", "internal_team", "agents"],
      agent_access: "true",
      status: "planned",
      auth_mode: "api_key_or_public_embed",
      health: "unknown",
      data_classification: "confidential",
      secrets_ref: "vault://e-any/cv-generator/service",
      allowed_agent_scopes: ["cv:create", "cv:read_template"],
      notes: "Public-callable CV generation service for e-any.online and partner websites.",
      metadata: %{
        "public_callable" => true,
        "embed_allowed" => true,
        "api_base_url" => "https://cv.e-any.online/api",
        "service_slug" => "cv-generator"
      }
    }
  end

  def ensure_cv_generator_registered do
    with {:ok, service} <- Payments.upsert_service(@cv_generator) do
      ensure_internal_tool()
      {:ok, service}
    end
  end

  def cv_generator_card do
    %{
      slug: @cv_generator.slug,
      name: @cv_generator.name,
      base_url: "https://cv.e-any.online/",
      api_endpoint: @cv_generator.endpoint_url,
      gateway_endpoint: "/api/public-services/cv-generator/generate",
      embed_url: "https://cv.e-any.online/embed",
      docs_url: "https://cv.e-any.online/docs",
      status: "planned",
      callable_from: ["agentandbot.com", "external websites", "agents"],
      auth_modes: ["api_key", "signed_embed", "public_demo"],
      pricing: %{
        price_per_request_cents: @cv_generator.price_per_request,
        currency: "USDC cents"
      },
      data_policy: %{
        stores_credentials: false,
        stores_generated_cv: "optional",
        pii_classification: "confidential",
        recommended_retention_days: 30
      },
      agent_scopes: ["cv:create", "cv:read_template"]
    }
  end

  defp ensure_internal_tool do
    if InternalTools.get_tool("cv-generator") do
      :ok
    else
      InternalTools.create_tool(cv_generator_internal_tool())
    end
  end
end
