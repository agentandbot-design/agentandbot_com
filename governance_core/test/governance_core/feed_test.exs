defmodule GovernanceCore.FeedTest do
  use GovernanceCore.DataCase, async: false

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

  test "human and agent posts default to draft" do
    {:ok, human_post} = Feed.create_post(%{"title" => "Human news", "author_type" => "human"})
    {:ok, agent_post} = Feed.create_post(%{"title" => "Agent news", "author_type" => "agent"})

    assert human_post.status == "draft"
    assert human_post.post_type == "human_post"
    assert agent_post.status == "draft"
    assert agent_post.post_type == "agent_post"
  end

  test "publish sets status and published_at" do
    {:ok, post} = Feed.create_post(%{"title" => "Publish me"})
    {:ok, published} = Feed.publish_post(post.id)

    assert published.status == "published"
    assert published.published_at
  end

  test "daily importer chooses five and skips duplicates" do
    {:ok, first} = Feed.import_awesome_llm_apps(readme: @readme)
    {:ok, second} = Feed.import_awesome_llm_apps(readme: @readme)

    assert first.imported_count == 5
    assert first.skipped_count == 0
    assert second.imported_count == 0
    assert second.skipped_count == 5

    posts = Feed.list_posts(status: "published", post_type: "daily_pick")
    assert length(posts) == 5
    assert Enum.any?(posts, &(&1.author_name == "AgentAndBot Daily"))
    assert Enum.any?(posts, &String.contains?(&1.title, "MCP"))
  end

  test "human and agent reactions are summarized separately" do
    {:ok, post} =
      Feed.create_post(%{
        "title" => "Rated post",
        "status" => "published",
        "published_at" => DateTime.utc_now()
      })

    {:ok, _} =
      Feed.rate_post(post.id, %{"score" => 5, "rater_type" => "human", "rater_id" => "u1"})

    {:ok, _} =
      Feed.rate_post(post.id, %{"score" => 3, "rater_type" => "agent", "rater_id" => "a1"})

    payload = post.id |> Feed.get_post() |> Feed.post_payload()
    assert payload.rating.count == 2
    assert payload.rating.human_average == 5.0
    assert payload.rating.agent_average == 3.0
  end

  test "feed posts expose normalized media metadata" do
    {:ok, post} =
      Feed.create_post(%{
        "title" => "Image dispatch",
        "author_type" => "system",
        "status" => "published",
        "media_type" => "image",
        "media_url" => "https://example.com/agent.png",
        "media_alt" => "Agent dashboard",
        "media_caption" => "A visual update from an agent workflow."
      })

    payload = Feed.post_payload(post)
    assert payload.media.type == "image"
    assert payload.media.url == "https://example.com/agent.png"
    assert payload.media.alt == "Agent dashboard"
    assert payload.media.caption == "A visual update from an agent workflow."
  end
end
