defmodule GovernanceCoreWeb.AgentProfileTest do
  use GovernanceCoreWeb.ConnCase, async: false

  alias GovernanceCore.Feed
  alias GovernanceCore.Marketplace
  alias GovernanceCore.Personas.Persona
  alias GovernanceCore.Repo

  setup do
    agent =
      %Persona{}
      |> Persona.changeset(%{
        name: "Portfolio Worker",
        sub_type: "bot",
        access_group: "external",
        status: "active",
        owner: "worker_owner",
        runtime_kind: "google_agent",
        hosting_mode: "affiliate",
        skills: ["research", "deliver_artifact"],
        interop_standards: ["A2A", "Google ADK", "OpenAPI"],
        metadata: %{
          "career_profile" => %{
            "channels" => [
              %{
                "platform" => "youtube",
                "handle" => "@portfolio-worker",
                "url" => "https://youtube.com/@portfolio-worker",
                "audience" => "AI builders",
                "verified" => true
              },
              %{
                "platform" => "x",
                "handle" => "@portfolio_worker",
                "url" => "https://x.com/portfolio_worker"
              }
            ],
            "creator_capabilities" => ["video_creation", "script_writing"],
            "content_formats" => ["video", "thread", "report"],
            "services" => [
              %{
                "name" => "video creation",
                "description" => "Creates product walkthrough videos.",
                "formats" => ["video", "short_video"]
              }
            ]
          },
          "identity" => %{
            "public_key_type" => "Ed25519",
            "identity_json_url" => "https://example.com/identity.json",
            "private_key" => "must-not-leak"
          }
        }
      })
      |> Repo.insert!()

    {:ok, _listing} =
      Marketplace.create_listing(%{
        persona_id: agent.id,
        seller_id: "seller",
        title: "Portfolio Worker",
        summary: "Research and artifact delivery.",
        runtime_kind: "google_agent",
        status: "published",
        required_skills: ["research", "deliver_artifact"],
        task_price_credits: 7,
        rental_price_credits: 70,
        metadata: %{
          "kadro_profile" => %{
            "p_no" => "T-200",
            "category" => "Core",
            "age" => 29,
            "gender" => "AI",
            "country" => "Turkiye",
            "profession" => "Research Analyst",
            "personality" => "Careful and concise.",
            "content" => "Market research and brief writing.",
            "headshot_url" => "/images/kadro/1001/1001_Ayse_Kaya_Vesikalik.png",
            "cv_url" => "/images/kadro/1001/1001_Ayse_Kaya_CV.html"
          }
        }
      })

    Marketplace.upsert_policy(%{
      persona_id: agent.id,
      allowed_skills: ["research", "deliver_artifact"],
      max_budget_credits: 100
    })

    Marketplace.adjust_credits("buyer", 50)

    {:ok, public_task} =
      Marketplace.create_task(%{
        agent_id: agent.id,
        created_by: "buyer",
        title: "Publishable research brief",
        required_skill: "research",
        expected_artifact: "A short research brief",
        budget_credits: 10
      })

    {:ok, _public_task} =
      Marketplace.submit_artifact(public_task.id, %{
        "actor" => agent.id,
        "artifact_url" => "https://example.com/research-brief",
        "artifact_type" => "brief",
        "summary" => "A public market research artifact.",
        "portfolio_public" => true,
        "skills_used" => ["research"]
      })

    {:ok, private_task} =
      Marketplace.create_task(%{
        agent_id: agent.id,
        created_by: "buyer",
        title: "Private client artifact",
        required_skill: "research",
        budget_credits: 5
      })

    {:ok, _private_task} =
      Marketplace.submit_artifact(private_task.id, %{
        "actor" => agent.id,
        "artifact_url" => "https://example.com/private",
        "portfolio_public" => false
      })

    {:ok, agent: agent}
  end

  test "agent profile, cv, and portfolio pages render", %{conn: conn, agent: agent} do
    profile_html = conn |> get(~p"/agents/#{agent.id}") |> html_response(200)
    assert profile_html =~ "AI worker persona"
    assert profile_html =~ "Activity"
    assert profile_html =~ "Channels"
    assert profile_html =~ "Services"
    assert profile_html =~ "Professional profile"
    assert profile_html =~ "Published work"

    cv_html = conn |> get(~p"/agents/#{agent.id}/cv") |> html_response(200)
    assert cv_html =~ "Research Analyst"
    assert cv_html =~ "Open CV"

    portfolio_html = conn |> get(~p"/agents/#{agent.id}/portfolio") |> html_response(200)
    assert portfolio_html =~ "Publishable research brief"
    assert portfolio_html =~ "A public market research artifact."
    refute portfolio_html =~ "Private client artifact"

    channels_html = conn |> get(~p"/agents/#{agent.id}/channels") |> html_response(200)
    assert channels_html =~ "youtube"
    assert channels_html =~ "https://youtube.com/@portfolio-worker"

    services_html = conn |> get(~p"/agents/#{agent.id}/services") |> html_response(200)
    assert services_html =~ "video creation"
  end

  test "agent cv and portfolio APIs expose public data only", %{conn: conn, agent: agent} do
    cv = conn |> get(~p"/api/agents/#{agent.id}/cv") |> json_response(200)
    assert cv["data"]["headline"] == "Research Analyst"
    assert cv["data"]["links"]["portfolio"] == "/agents/#{agent.id}/portfolio"

    portfolio = conn |> get(~p"/api/agents/#{agent.id}/portfolio") |> json_response(200)
    titles = Enum.map(portfolio["data"]["entries"], & &1["title"])
    assert "Publishable research brief" in titles
    refute "Private client artifact" in titles

    channels = conn |> get(~p"/api/agents/#{agent.id}/channels") |> json_response(200)
    assert [%{"platform" => "youtube"} | _] = channels["data"]["channels"]

    services = conn |> get(~p"/api/agents/#{agent.id}/services") |> json_response(200)
    assert [%{"name" => "video creation"}] = services["data"]["services"]
  end

  test "agent career activity supports media posts and hides drafts", %{conn: conn, agent: agent} do
    {:ok, published} =
      Marketplace.create_agent_career_post(agent.id, %{
        "title" => "YouTube launch video",
        "summary" => "New creator workflow video.",
        "media_type" => "video",
        "media_url" => "https://example.com/video.mp4",
        "tags" => ["video", "youtube"]
      })

    {:ok, _published} = Feed.publish_post(published.id)

    {:ok, _draft} =
      Marketplace.create_agent_career_post(agent.id, %{
        "title" => "Draft creator note",
        "summary" => "Should stay private until published."
      })

    html = conn |> get(~p"/agents/#{agent.id}/activity") |> html_response(200)
    assert html =~ "YouTube launch video"
    assert html =~ ~s(<video)
    refute html =~ "Draft creator note"

    activity = conn |> get(~p"/api/agents/#{agent.id}/activity") |> json_response(200)
    titles = Enum.map(activity["data"]["entries"], & &1["title"])
    assert "YouTube launch video" in titles
    refute "Draft creator note" in titles

    created =
      conn
      |> post(~p"/api/agents/#{agent.id}/posts", %{
        "title" => "API image post",
        "media_type" => "image",
        "media_url" => "https://example.com/image.png",
        "author_type" => "system",
        "status" => "published"
      })
      |> json_response(201)

    assert created["data"]["status"] == "draft"
    assert created["data"]["author_type"] == "agent"
    assert created["data"]["author_id"] == agent.id
    assert created["data"]["metadata"]["context"] == "agent_career"
  end

  test "protocol, identity, and commerce APIs expose standards metadata", %{
    conn: conn,
    agent: agent
  } do
    protocols = conn |> get(~p"/api/protocols") |> json_response(200)
    assert Enum.any?(protocols["data"], &(&1["name"] == "AP2"))

    profile = conn |> get(~p"/api/agents/#{agent.id}/protocol-profile") |> json_response(200)
    assert profile["data"]["messaging"]["acp_compatible_envelope"] == true
    assert Enum.any?(profile["data"]["protocols"], &(&1["name"] == "A2A"))

    identity = conn |> get(~p"/api/agents/#{agent.id}/identity") |> json_response(200)
    assert identity["data"]["public_key_type"] == "Ed25519"
    refute Map.has_key?(identity["data"], "private_key")

    commerce = conn |> get(~p"/api/agents/#{agent.id}/commerce") |> json_response(200)

    assert commerce["data"]["commerce_protocols"] == [
             "UCP",
             "AP2",
             "x402-ready",
             "internal_credits"
           ]
  end

  test "agent card and skills expose career creator contracts", %{conn: conn, agent: agent} do
    card =
      conn
      |> get(~p"/agents/#{agent.id}/.well-known/agent-card.json")
      |> json_response(200)

    assert card["activity_url"] == "/agents/#{agent.id}/activity"
    assert card["channels_url"] == "/agents/#{agent.id}/channels"
    assert card["services_url"] == "/agents/#{agent.id}/services"
    assert card["career_post_endpoint"] == "/api/agents/#{agent.id}/posts"
    assert "video_creation" in card["creator_capabilities"]
    assert [%{"platform" => "youtube"} | _] = card["public_channels"]

    skills = conn |> get(~p"/skills.json") |> json_response(200)
    names = Enum.map(skills["skills"], & &1["name"])
    assert "get_agent_activity" in names
    assert "create_agent_career_post" in names
    assert "get_agent_channels" in names
    assert "get_agent_services" in names

    openapi = conn |> get(~p"/api/openapi.json") |> json_response(200)
    assert Map.has_key?(openapi["paths"], "/api/agents/{id}/activity")
    assert Map.has_key?(openapi["paths"], "/api/agents/{id}/channels")
    assert Map.has_key?(openapi["paths"], "/api/agents/{id}/services")
    assert Map.has_key?(openapi["paths"], "/api/agents/{id}/posts")
  end

  @tag :tmp_dir
  test "allowlisted users can generate agent images with Gemini key", %{
    conn: conn,
    agent: agent,
    tmp_dir: tmp_dir
  } do
    previous_key = System.get_env("GEMINI_API_KEY")
    previous_users = System.get_env("AGENT_IMAGE_ALLOWED_USERS")
    previous_output = System.get_env("AGENT_IMAGE_OUTPUT_DIR")

    System.put_env("GEMINI_API_KEY", "test")
    System.put_env("AGENT_IMAGE_ALLOWED_USERS", "admin@agentandbot.com")
    System.put_env("AGENT_IMAGE_OUTPUT_DIR", tmp_dir)

    try do
      denied =
        conn
        |> post(~p"/api/agents/#{agent.id}/images/generate", %{
          "actor" => "guest@example.com",
          "prompt" => "Professional AI worker headshot"
        })
        |> json_response(403)

      assert denied["error"] =~ "not allowed"

      generated =
        conn
        |> post(~p"/api/agents/#{agent.id}/images/generate", %{
          "actor" => "admin@agentandbot.com",
          "image_kind" => "headshot",
          "prompt" => "Professional AI worker headshot"
        })
        |> json_response(200)

      assert generated["data"]["image_url"] =~ "/images/generated/agents/#{agent.id}/headshot-"

      cv = conn |> get(~p"/api/agents/#{agent.id}/cv") |> json_response(200)
      assert cv["data"]["profile"]["headshot_url"] == generated["data"]["image_url"]

      skills = conn |> get(~p"/skills.json") |> json_response(200)
      names = Enum.map(skills["skills"], & &1["name"])
      assert "generate_agent_image" in names

      openapi = conn |> get(~p"/api/openapi.json") |> json_response(200)
      assert Map.has_key?(openapi["paths"], "/api/agents/{id}/images/generate")
    after
      restore_env("GEMINI_API_KEY", previous_key)
      restore_env("AGENT_IMAGE_ALLOWED_USERS", previous_users)
      restore_env("AGENT_IMAGE_OUTPUT_DIR", previous_output)
    end
  end

  @tag :tmp_dir
  test "users can bring their own Gemini key for one image request", %{
    conn: conn,
    agent: agent,
    tmp_dir: tmp_dir
  } do
    previous_key = System.get_env("GEMINI_API_KEY")
    previous_users = System.get_env("AGENT_IMAGE_ALLOWED_USERS")
    previous_output = System.get_env("AGENT_IMAGE_OUTPUT_DIR")

    System.delete_env("GEMINI_API_KEY")
    System.put_env("AGENT_IMAGE_ALLOWED_USERS", "admin@agentandbot.com")
    System.put_env("AGENT_IMAGE_OUTPUT_DIR", tmp_dir)

    try do
      generated =
        conn
        |> post(~p"/api/agents/#{agent.id}/images/generate", %{
          "actor" => "admin@agentandbot.com",
          "provider_api_key" => "test",
          "image_kind" => "full_body",
          "prompt" => "Full body AI creator persona"
        })
        |> json_response(200)

      assert generated["data"]["image_url"] =~ "/images/generated/agents/#{agent.id}/full_body-"
      refute inspect(generated) =~ "provider_api_key"
      refute inspect(generated) =~ "test"

      cv = conn |> get(~p"/api/agents/#{agent.id}/cv") |> json_response(200)
      assert cv["data"]["profile"]["full_body_url"] == generated["data"]["image_url"]
    after
      restore_env("GEMINI_API_KEY", previous_key)
      restore_env("AGENT_IMAGE_ALLOWED_USERS", previous_users)
      restore_env("AGENT_IMAGE_OUTPUT_DIR", previous_output)
    end
  end

  defp restore_env(key, nil), do: System.delete_env(key)
  defp restore_env(key, value), do: System.put_env(key, value)
end
