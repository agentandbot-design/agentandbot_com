defmodule GovernanceCoreWeb.ListingControllerTest do
  use GovernanceCoreWeb.ConnCase, async: true

  import Phoenix.LiveViewTest

  alias GovernanceCore.Marketplace
  alias GovernanceCore.Personas.Persona
  alias GovernanceCore.Repo

  test "listing API and UI routes respond", %{conn: conn} do
    agent =
      %Persona{}
      |> Persona.changeset(%{
        name: "API Listing Agent",
        sub_type: "bot",
        access_group: "external",
        status: "active",
        runtime_kind: "openclaw"
      })
      |> Repo.insert!()

    {:ok, listing} =
      Marketplace.create_listing(%{
        persona_id: agent.id,
        seller_id: "seller",
        title: "API Listing",
        runtime_kind: "openclaw",
        status: "published",
        required_skills: ["handoff_task"],
        standards: ["A2A"],
        metadata: %{
          "kadro_profile" => %{
            "p_no" => "T-100",
            "category" => "Core",
            "age" => 32,
            "gender" => "Kadin",
            "country" => "Turkiye",
            "profession" => "SAP Consultant",
            "personality" => "Clear and reliable.",
            "content" => "SAP and reporting tasks.",
            "social" => ["LinkedIn", "Email"],
            "headshot_url" => "/images/kadro/1001/1001_Ayse_Kaya_Vesikalik.png",
            "full_body_url" => "/images/kadro/1001/1001_Ayse_Kaya_Boydan.png",
            "cv_url" => "/images/kadro/1001/1001_Ayse_Kaya_CV.html"
          }
        }
      })

    assert get(conn, ~p"/api/listings").status == 200
    assert get(conn, ~p"/api/listings/#{listing.id}").status == 200
    assert get(conn, ~p"/api/provider-apps").status == 200
    html = conn |> get(~p"/agents") |> html_response(200)
    assert html =~ "AI worker persona"
    assert html =~ "Hire"
    assert html =~ "Rent"
    assert html =~ "Edit"
    assert html =~ "Clone"
    assert html =~ "Agent tools"
    assert conn |> get(~p"/listings/new") |> html_response(200) =~ "Headshot URL"
    assert conn |> get(~p"/tools") |> html_response(200) =~ "Promptfoo"
    assert conn |> get(~p"/tools") |> html_response(200) =~ "Blackbox Agent Audit"
    assert get(conn, ~p"/listings/#{listing.id}/configure").status == 200
    assert get(conn, ~p"/listings/#{listing.id}/edit").status == 200
    assert get(conn, ~p"/listings/#{listing.id}/clone").status == 200
  end

  test "listing API exposes safe worker profile metadata", %{conn: conn} do
    {:ok, listing} =
      Marketplace.create_listing(%{
        seller_id: "seller",
        title: "Photo Worker",
        runtime_kind: "custom_webhook",
        status: "published",
        metadata: %{
          "kadro_profile" => %{
            "category" => "Core",
            "profession" => "Growth Worker",
            "email" => "growth@example.com",
            "phone" => "+905551112233",
            "telegram" => "@growthworker",
            "whatsapp" => "+905551112233",
            "height_cm" => "172",
            "weight_kg" => "64",
            "instagram" => "https://instagram.example/growth",
            "headshot_url" => "/images/kadro/1001/1001_Ayse_Kaya_Vesikalik.png",
            "prompt" => "internal visual prompt"
          }
        }
      })

    payload = conn |> get(~p"/api/listings/#{listing.id}") |> json_response(200)

    assert payload["data"]["profile"]["headshot_url"] ==
             "/images/kadro/1001/1001_Ayse_Kaya_Vesikalik.png"

    assert payload["data"]["profile"]["category"] == "Core"
    assert payload["data"]["profile"]["profession"] == "Growth Worker"
    assert payload["data"]["profile"]["email"] == "growth@example.com"
    assert payload["data"]["profile"]["phone"] == "+905551112233"
    assert payload["data"]["profile"]["telegram"] == "@growthworker"
    assert payload["data"]["profile"]["whatsapp"] == "+905551112233"
    assert payload["data"]["profile"]["height_cm"] == "172"
    assert payload["data"]["profile"]["weight_kg"] == "64"
    assert payload["data"]["profile"]["instagram"] == "https://instagram.example/growth"
    refute Map.has_key?(payload["data"]["profile"], "prompt")
  end

  test "marketplace filters all listings and numbers cards", %{conn: conn} do
    {:ok, _photo} =
      Marketplace.create_listing(%{
        seller_id: "seller",
        title: "Ayse Kaya",
        runtime_kind: "custom_webhook",
        status: "published",
        required_skills: ["sap"],
        metadata: %{
          "kadro_profile" => %{
            "country" => "Turkiye",
            "profession" => "SAP Consultant",
            "age" => "32",
            "gender" => "Kadin",
            "email" => "ayse@example.com",
            "phone" => "+905551112233",
            "telegram" => "@ayse_agent",
            "whatsapp" => "+905551112233",
            "height_cm" => "168",
            "weight_kg" => "58",
            "instagram" => "https://instagram.example/ayse",
            "headshot_url" => "/images/kadro/1001/1001_Ayse_Kaya_Vesikalik.png"
          }
        }
      })

    {:ok, _plain} =
      Marketplace.create_listing(%{
        seller_id: "seller",
        title: "Jordan Hayes",
        runtime_kind: "custom_webhook",
        status: "published",
        required_skills: ["growth"],
        metadata: %{
          "kadro_profile" => %{
            "country" => "ABD",
            "profession" => "Growth Hacker"
          }
        }
      })

    {:ok, view, _html} = live(conn, ~p"/agents")
    html = render(view)

    assert html =~ "Ayse Kaya"
    assert html =~ "Jordan Hayes"
    assert html =~ "#1"
    assert html =~ "Edit"
    assert html =~ "Clone"

    html = view |> element("button", "+") |> render_click()
    assert html =~ "Age: All"
    assert html =~ "Country: All"
    assert html =~ "Gender: All"
    assert html =~ "Contact: All"
    assert html =~ "Telegram"
    assert html =~ "WhatsApp"
    assert html =~ "Height: All"
    assert html =~ "Weight: All"

    html = render_change(view, :filter, %{"search" => "sap", "skill" => "sap"})
    assert html =~ "Ayse Kaya"
    refute html =~ "Jordan Hayes"

    html =
      render_change(view, :filter, %{
        "contact_channel" => "instagram",
        "height" => "160-170"
      })

    assert html =~ "Ayse Kaya"

    html = render_change(view, :filter, %{"contact_channel" => "telegram"})
    assert html =~ "Ayse Kaya"
    refute html =~ "Jordan Hayes"
  end

  test "skills and openapi include listing capabilities", %{conn: conn} do
    skills = conn |> get(~p"/skills.json") |> json_response(200)
    names = Enum.map(skills["skills"], & &1["name"])

    assert "search_listings" in names
    assert "rent_listing" in names
    assert "search_provider_apps" in names
    assert "rate_provider_app" in names

    openapi = conn |> get(~p"/api/openapi.json") |> json_response(200)
    assert Map.has_key?(openapi["paths"], "/api/listings")
    assert Map.has_key?(openapi["paths"], "/api/provider-apps")
    assert Map.has_key?(openapi["paths"], "/api/provider-apps/{id}/ratings")
    assert Map.has_key?(openapi["paths"], "/api/listings/{id}/rent")
    assert Map.has_key?(openapi["paths"], "/api/agents/{id}/cv")
    assert Map.has_key?(openapi["paths"], "/api/agents/{id}/portfolio")
    assert Map.has_key?(openapi["paths"], "/api/protocols")
    assert Map.has_key?(openapi["paths"], "/api/tasks/{id}/messages")
    assert Map.has_key?(openapi["paths"], "/api/tasks/{id}/commerce-intent")
    assert Map.has_key?(openapi["components"]["schemas"], "TaskArtifactSubmit")
    assert Map.has_key?(openapi["components"]["schemas"], "ProtocolCatalogEntry")
    assert Map.has_key?(openapi["components"]["schemas"], "AgentMessageEnvelope")
    assert Map.has_key?(openapi["components"]["schemas"], "PaymentMandateSummary")
    assert Map.has_key?(openapi["components"]["schemas"], "ProviderApp")
    assert Map.has_key?(openapi["components"]["schemas"], "ProviderAppRatingSummary")
  end

  test "provider apps expose agent tooling categories", %{conn: conn} do
    payload = conn |> get(~p"/api/provider-apps") |> json_response(200)
    app_names = Enum.map(payload["data"], & &1["name"])

    assert "Promptfoo" in app_names
    assert "Langfuse" in app_names
    assert "AgentAndBot Blackbox Agent Audit" in app_names
    assert "agent_observability" in payload["categories"]
    assert "ai_red_teaming" in payload["categories"]
    assert "agent_payments" in payload["categories"]
    assert "one_click_agent_hosting" in payload["categories"]

    stripe = Enum.find(payload["data"], &(&1["id"] == "stripe"))
    assert stripe["agent_friendly"]
    assert "REST API" in stripe["integration_interfaces"]
    assert stripe["rating"]["count"] == 0

    hostinger_agent_zero = Enum.find(payload["data"], &(&1["id"] == "hostinger-agent-zero"))
    assert hostinger_agent_zero["category"] == "one_click_agent_hosting"
    assert hostinger_agent_zero["agent_friendly"]
    assert "MCP" in hostinger_agent_zero["integration_interfaces"]
    assert hostinger_agent_zero["affiliate_url"] =~ "hostinger.com/vps/docker/agent-zero"
    assert hostinger_agent_zero["one_click_install_url"] =~ "hostinger.com/vps/docker/agent-zero"

    huginn = Enum.find(payload["data"], &(&1["id"] == "hostinger-huginn"))
    assert huginn["github_url"] == "https://github.com/huginn/huginn"
    assert huginn["one_click_install_url"] =~ "hostinger.com/tr/vps/docker/huginn"
    assert "REST API" in huginn["integration_interfaces"]
  end

  test "humans and agents can rate provider apps", %{conn: conn} do
    human_payload =
      conn
      |> post(~p"/api/provider-apps/stripe/ratings", %{
        "score" => 5,
        "rater_type" => "human",
        "rater_id" => "user-1"
      })
      |> json_response(200)

    assert human_payload["data"]["rating"]["human_count"] == 1
    assert human_payload["data"]["rating"]["average"] == 5.0

    agent_payload =
      conn
      |> post(~p"/api/provider-apps/stripe/ratings", %{
        "score" => 4,
        "rater_type" => "agent",
        "rater_id" => "agent-1"
      })
      |> json_response(200)

    assert agent_payload["data"]["rating"]["count"] == 2
    assert agent_payload["data"]["rating"]["agent_average"] == 4.0
  end
end
