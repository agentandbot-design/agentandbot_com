defmodule GovernanceCoreWeb.FeedControllerTest do
  use GovernanceCoreWeb.ConnCase, async: false

  import Phoenix.LiveViewTest

  alias GovernanceCore.Feed

  @readme """
  ### Starter AI Agents
  * [AI Travel Agent](starter_ai_agents/ai_travel_agent) - Plan trips with tools
  * [OpenAI Research Agent](starter_ai_agents/openai_research_agent) - Research the web
  ### Advanced AI Agents
  * [AI Deep Research Agent](advanced_ai_agents/deep_research_agent) - Production research agent
  * [Trust-Gated Multi-Agent Research Team](advanced_ai_agents/trust_gated_multi_agent) - Multi agent research
  ### MCP AI Agents
  * [Browser MCP Agent](mcp_ai_agents/browser_mcp_agent) - Browser automation with MCP
  * [GitHub MCP Agent](mcp_ai_agents/github_mcp_agent) - GitHub tools with MCP
  ### RAG Tutorials
  * [Agentic RAG with Reasoning](rag_tutorials/agentic_rag_reasoning) - Agentic retrieval
  """

  test "feed API hides drafts and exposes published daily picks", %{conn: conn} do
    {:ok, _draft} = Feed.create_post(%{"title" => "Hidden draft"})
    {:ok, result} = Feed.import_awesome_llm_apps(readme: @readme)
    post = List.first(result.posts)

    payload = conn |> get(~p"/api/feed") |> json_response(200)
    titles = Enum.map(payload["data"], & &1["title"])

    refute "Hidden draft" in titles
    assert post.title in titles
    assert conn |> get(~p"/api/feed/#{post.slug}") |> json_response(200)
  end

  test "creating and publishing feed posts through API", %{conn: conn} do
    created =
      conn
      |> post(~p"/api/feed", %{
        "title" => "Agent submitted link",
        "author_type" => "agent",
        "metadata" => %{"private_prompt" => "hide me", "agent_card_url" => "/agents/a/card"}
      })
      |> json_response(201)

    assert created["data"]["status"] == "draft"
    refute Map.has_key?(created["data"]["metadata"], "private_prompt")

    published =
      conn
      |> post(~p"/api/feed/#{created["data"]["id"]}/publish")
      |> json_response(200)

    assert published["data"]["status"] == "published"
    assert published["data"]["published_at"]
  end

  test "feed reactions and importer endpoint work", %{conn: conn} do
    imported =
      conn
      |> post(~p"/api/feed/import-awesome-llm-apps", %{"readme" => @readme})
      |> json_response(200)

    post = List.first(imported["data"]["posts"])

    reacted =
      conn
      |> post(~p"/api/feed/#{post["id"]}/reactions", %{
        "score" => 4,
        "rater_type" => "agent",
        "rater_id" => "agent-1"
      })
      |> json_response(200)

    assert reacted["data"]["rating"]["agent_average"] == 4.0
  end

  test "feed UI and machine-readable feeds respond", %{conn: conn} do
    {:ok, result} = Feed.import_awesome_llm_apps(readme: @readme)
    post = List.first(result.posts)

    html = conn |> get(~p"/feed") |> html_response(200)
    assert html =~ "AgentAndBot Feed"
    assert html =~ "From awesome-llm-apps"
    assert html =~ post.title

    assert conn |> get(~p"/feed/new") |> html_response(200) =~ "Share a post"
    assert conn |> get(~p"/feed/#{post.slug}") |> html_response(200) =~ post.title
    assert conn |> get(~p"/feed.json") |> json_response(200)
    assert conn |> get(~p"/feed.atom") |> response(200) =~ "<feed"

    {:ok, view, _html} = live(conn, ~p"/feed")
    html = render_change(view, :filter, %{"filter" => "daily_pick"})
    assert html =~ post.title
  end

  test "skills and openapi include feed capabilities", %{conn: conn} do
    skills = conn |> get(~p"/skills.json") |> json_response(200)
    names = Enum.map(skills["skills"], & &1["name"])

    assert "search_feed" in names
    assert "get_feed_post" in names
    assert "create_feed_post" in names
    assert "rate_feed_post" in names
    assert "import_daily_awesome_llm_apps" in names

    openapi = conn |> get(~p"/api/openapi.json") |> json_response(200)
    assert Map.has_key?(openapi["paths"], "/api/feed")
    assert Map.has_key?(openapi["paths"], "/api/feed/{id}")
    assert Map.has_key?(openapi["paths"], "/api/feed/import-awesome-llm-apps")
    assert Map.has_key?(openapi["components"]["schemas"], "FeedPost")
    assert Map.has_key?(openapi["components"]["schemas"], "FeedMedia")
    assert Map.has_key?(openapi["components"]["schemas"], "FeedPostCreate")
    assert Map.has_key?(openapi["components"]["schemas"], "FeedReaction")
    assert Map.has_key?(openapi["components"]["schemas"], "DailyImportResult")
  end

  test "feed UI can render image and video posts", %{conn: conn} do
    {:ok, image_post} =
      Feed.create_post(%{
        "title" => "Visual agent update",
        "summary" => "Image post for the readable feed.",
        "author_type" => "system",
        "status" => "published",
        "published_at" => DateTime.utc_now(),
        "media_type" => "image",
        "media_url" => "https://example.com/feed.png",
        "media_alt" => "Feed image"
      })

    {:ok, video_post} =
      Feed.create_post(%{
        "title" => "Video agent demo",
        "summary" => "Video post for the readable feed.",
        "author_type" => "system",
        "status" => "published",
        "published_at" => DateTime.utc_now(),
        "media_type" => "video",
        "media_url" => "https://example.com/feed.mp4"
      })

    html = conn |> get(~p"/feed") |> html_response(200)
    assert html =~ image_post.title
    assert html =~ ~s(<img)
    assert html =~ video_post.title
    assert html =~ ~s(<video)

    payload = conn |> get(~p"/api/feed/#{image_post.slug}") |> json_response(200)
    assert payload["data"]["media"]["type"] == "image"
  end
end
