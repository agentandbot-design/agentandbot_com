defmodule GovernanceCore.SwarmSearch do
  @moduledoc """
  Unified search across the local AgentAndBot swarm.
  """

  alias GovernanceCore.{Agents, Feed, InternalTools, Marketplace}
  alias GovernanceCore.Payment.Payments

  @default_limit 5

  def search(query, opts \\ []) do
    query = normalize_query(query)
    limit = Keyword.get(opts, :limit, @default_limit)

    if query == "" do
      empty_result(query)
    else
      groups = %{
        agents: search_agents(query, limit),
        tasks: search_tasks(query, limit),
        feed: search_feed(query, limit),
        tools: search_tools(query, limit),
        internal_tools: search_internal_tools(query, limit),
        services: search_services(query, limit)
      }

      %{
        query: query,
        total: groups |> Map.values() |> Enum.map(&length/1) |> Enum.sum(),
        groups: groups
      }
    end
  end

  defp empty_result(query) do
    %{
      query: query,
      total: 0,
      groups: %{agents: [], tasks: [], feed: [], tools: [], internal_tools: [], services: []}
    }
  end

  defp search_agents(query, limit) do
    query
    |> Agents.search()
    |> Enum.take(limit)
    |> Enum.map(fn agent ->
      %{
        type: :agent,
        title: agent.name,
        subtitle: agent.role || agent.description || "Persona",
        url: "/agents/#{agent.id}",
        status: agent.status,
        meta: compact([agent.sub_type, agent.access_group, skills_label(agent.skills)])
      }
    end)
  end

  defp search_tasks(query, limit) do
    Marketplace.list_tasks()
    |> Enum.filter(&matches?(&1, query, [:title, :instructions, :required_skill, :status]))
    |> Enum.take(limit)
    |> Enum.map(fn task ->
      %{
        type: :task,
        title: task.title,
        subtitle: task.instructions || task.expected_artifact || "Marketplace task",
        url: "/scenarios",
        status: task.status,
        meta: compact([task.required_skill, agent_name(task), credits_label(task.budget_credits)])
      }
    end)
  end

  defp search_feed(query, limit) do
    Feed.list_posts(status: "all", include_reactions: false)
    |> Enum.filter(&matches?(&1, query, [:title, :summary, :body, :author_name, :source_repo]))
    |> Enum.take(limit)
    |> Enum.map(fn post ->
      %{
        type: :feed,
        title: post.title,
        subtitle: post.summary || post.source_name || "Feed post",
        url: "/feed/#{post.slug}",
        status: post.status,
        meta: compact([post.author_name, post.post_type, tags_label(post.tags)])
      }
    end)
  end

  defp search_tools(query, limit) do
    Marketplace.provider_apps()
    |> Enum.filter(&tool_matches?(&1, query))
    |> Enum.take(limit)
    |> Enum.map(fn app ->
      %{
        type: :tool,
        title: app[:name],
        subtitle: app[:headline] || app[:description] || "Provider app",
        url: "/tools",
        status: app[:status] || app[:category],
        meta: compact([app[:category], tags_label(app[:tags])])
      }
    end)
  end

  defp search_services(query, limit) do
    Payments.list_services()
    |> Enum.filter(&matches?(&1, query, [:name, :slug, :owner_wallet, :endpoint_url]))
    |> Enum.take(limit)
    |> Enum.map(fn service ->
      %{
        type: :service,
        title: service.name,
        subtitle: service.endpoint_url || "Payment service",
        url: "/payment/dashboard",
        status: if(service.active, do: "active", else: "inactive"),
        meta: compact([service.slug, price_label(service.price_per_request)])
      }
    end)
  end

  defp search_internal_tools(query, limit) do
    InternalTools.list_tools()
    |> Enum.filter(&internal_tool_matches?(&1, query))
    |> Enum.take(limit)
    |> Enum.map(fn tool ->
      %{
        type: :internal_tool,
        title: tool.name,
        subtitle: Map.get(tool, :notes) || tool.url || "Internal e-any.online tool",
        url: "/tools/internal",
        status: tool.status,
        meta: compact([tool.category, tool.container_name, tool.agent_access])
      }
    end)
  end

  defp tool_matches?(app, query) do
    searchable =
      [
        app[:name],
        app[:headline],
        app[:description],
        app[:category],
        app[:status],
        app[:tags],
        app[:capabilities],
        app[:best_for]
      ]

    contains_query?(searchable, query)
  end

  defp internal_tool_matches?(tool, query) do
    [
      tool.name,
      tool.slug,
      tool.url,
      tool.container_name,
      tool.category,
      tool.owner,
      tool.status,
      tool.health,
      Map.get(tool, :notes),
      tool.audience,
      tool.allowed_agent_scopes
    ]
    |> contains_query?(query)
  end

  defp matches?(struct, query, fields) do
    fields
    |> Enum.map(&Map.get(struct, &1))
    |> contains_query?(query)
  end

  defp contains_query?(values, query) do
    haystack =
      values
      |> List.wrap()
      |> List.flatten()
      |> Enum.reject(&is_nil/1)
      |> Enum.map_join(" ", &to_string/1)
      |> String.downcase()

    String.contains?(haystack, String.downcase(query))
  end

  defp normalize_query(query), do: query |> to_string() |> String.trim()

  defp compact(values) do
    values
    |> Enum.reject(&is_nil/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp skills_label(nil), do: nil
  defp skills_label([]), do: nil
  defp skills_label(skills), do: Enum.join(Enum.take(skills, 3), ", ")

  defp tags_label(nil), do: nil
  defp tags_label([]), do: nil
  defp tags_label(tags), do: Enum.join(Enum.take(tags, 3), ", ")

  defp credits_label(nil), do: nil
  defp credits_label(credits), do: "#{credits} credits"

  defp price_label(nil), do: nil
  defp price_label(cents), do: "#{cents} cents/request"

  defp agent_name(%{agent: %{name: name}}), do: name
  defp agent_name(_task), do: nil
end
