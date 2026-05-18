defmodule GovernanceCore.Feed.AwesomeLlmAppsImporter do
  @moduledoc """
  Imports five daily AgentAndBot picks from Shubhamsaboo/awesome-llm-apps.
  """

  import Ecto.Query

  alias GovernanceCore.Feed
  alias GovernanceCore.Feed.Post
  alias GovernanceCore.Repo

  @source_repo "Shubhamsaboo/awesome-llm-apps"
  @source_url "https://github.com/Shubhamsaboo/awesome-llm-apps"
  @readme_url "https://raw.githubusercontent.com/Shubhamsaboo/awesome-llm-apps/main/README.md"
  @daily_count 5

  def import_daily(opts \\ []) do
    with {:ok, readme} <- read_readme(opts) do
      picks =
        readme
        |> extract_items()
        |> rank_items()
        |> Enum.take(Keyword.get(opts, :limit, @daily_count))

      results = Enum.map(picks, &create_daily_pick/1)

      {:ok,
       %{
         source_repo: @source_repo,
         imported_count: Enum.count(results, &match?({:ok, _}, &1)),
         skipped_count: Enum.count(results, &match?({:skipped, _}, &1)),
         error_count: Enum.count(results, &match?({:error, _}, &1)),
         posts:
           Enum.flat_map(results, fn
             {:ok, post} -> [Feed.post_payload(post)]
             _ -> []
           end)
       }}
    end
  end

  def extract_items(readme) do
    readme
    |> String.split("\n")
    |> Enum.reduce({nil, []}, fn line, {category, items} ->
      cond do
        String.starts_with?(line, "### ") ->
          {clean_title(String.replace_prefix(line, "### ", "")), items}

        Regex.match?(~r/^\s*\*\s+\[[^\]]+\]\([^)]+\)/, line) ->
          case parse_item(line, category) do
            nil -> {category, items}
            item -> {category, [item | items]}
          end

        true ->
          {category, items}
      end
    end)
    |> elem(1)
    |> Enum.reverse()
  end

  def rank_items(items) do
    items
    |> Enum.map(&Map.put(&1, :score, score_item(&1)))
    |> Enum.sort_by(&{-&1.score, &1.category, &1.title})
  end

  defp read_readme(opts) do
    cond do
      readme = Keyword.get(opts, :readme) ->
        {:ok, readme}

      path = Keyword.get(opts, :path) ->
        File.read(path)

      true ->
        case Req.get(@readme_url, receive_timeout: 15_000) do
          {:ok, %{status: status, body: body}} when status in 200..299 -> {:ok, body}
          {:ok, %{status: status}} -> {:error, {:source_unavailable, status}}
          {:error, reason} -> {:error, {:source_unavailable, reason}}
        end
    end
  end

  defp parse_item(line, category) do
    with [_, title, href] <- Regex.run(~r/\[([^\]]+)\]\(([^)]+)\)/, line) do
      %{
        title: clean_title(title),
        url: absolute_url(href),
        category: category || "Awesome LLM Apps",
        summary: summary_for(line),
        tags: tags_for(title, category)
      }
    else
      _ -> nil
    end
  end

  defp create_daily_pick(item) do
    if Repo.exists?(from p in Post, where: p.source_url == ^item.url or p.url == ^item.url) do
      {:skipped, item.url}
    else
      insert_daily_pick(item)
    end
  end

  defp insert_daily_pick(item) do
    attrs = %{
      "title" => item.title,
      "summary" => item.summary,
      "body" =>
        "#{item.title} is a daily AgentAndBot pick from awesome-llm-apps. Review the source template, adapt it to your worker stack, and publish a portfolio artifact when you ship it.",
      "url" => item.url,
      "source_name" => "awesome-llm-apps",
      "source_url" => item.url,
      "source_repo" => @source_repo,
      "post_type" => "daily_pick",
      "author_type" => "system",
      "author_id" => "agentandbot-daily",
      "author_name" => "AgentAndBot Daily",
      "status" => "published",
      "published_at" => DateTime.utc_now() |> DateTime.truncate(:second),
      "tags" => item.tags,
      "metadata" => %{
        "source_home" => @source_url,
        "category" => item.category,
        "selection_policy" => "ai_curated_deterministic_fallback",
        "source_confidence" => "repository_readme"
      }
    }

    case Feed.create_post(attrs) do
      {:ok, post} ->
        {:ok, post}

      {:error, changeset} ->
        if duplicate_slug?(changeset), do: {:skipped, item.url}, else: {:error, changeset}
    end
  end

  defp score_item(item) do
    text = "#{item.title} #{item.category} #{Enum.join(item.tags, " ")}" |> String.downcase()

    [
      {"mcp", 9},
      {"multi", 8},
      {"agent", 7},
      {"rag", 6},
      {"skills", 6},
      {"framework", 5},
      {"crash course", 5},
      {"voice", 4},
      {"memory", 4},
      {"research", 3}
    ]
    |> Enum.reduce(0, fn {term, points}, total ->
      if String.contains?(text, term), do: total + points, else: total
    end)
  end

  defp duplicate_slug?(changeset) do
    Enum.any?(changeset.errors, fn
      {:slug, {_message, opts}} -> opts[:constraint] == :unique
      _ -> false
    end)
  end

  defp clean_title(value) do
    value
    |> to_string()
    |> String.replace(~r/[^\p{L}\p{N}\s\-\+\&\:\/\(\)]/u, "")
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end

  defp summary_for(line) do
    line
    |> String.replace(~r/^\s*\*\s+/, "")
    |> String.replace(~r/\[[^\]]+\]\([^)]+\)/, "")
    |> String.trim()
    |> String.trim_leading("-")
    |> String.trim()
    |> case do
      "" -> "Runnable AI agent or LLM app template from awesome-llm-apps."
      summary -> summary
    end
  end

  defp tags_for(title, category) do
    text = "#{title} #{category}" |> String.downcase()

    ["agent", "rag", "mcp", "multi-agent", "voice", "skills", "framework", "memory"]
    |> Enum.filter(&String.contains?(text, &1))
    |> then(fn tags -> Enum.uniq([category || "Awesome LLM Apps" | tags]) end)
  end

  defp absolute_url("http" <> _ = url), do: url
  defp absolute_url("#" <> _ = anchor), do: @source_url <> anchor
  defp absolute_url(path), do: @source_url <> "/tree/main/" <> String.trim_leading(path, "/")
end
