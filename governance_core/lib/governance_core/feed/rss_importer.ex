defmodule GovernanceCore.Feed.RssImporter do
  @moduledoc """
  Imports RSS/Atom entries into the AgentAndBot feed.
  """

  alias GovernanceCore.Feed

  @default_limit 10

  def import(opts \\ []) do
    with {:ok, xml} <- read_feed(opts) do
      url = Keyword.get(opts, :url)
      limit = Keyword.get(opts, :limit, @default_limit)

      results =
        xml
        |> extract_entries()
        |> Enum.take(limit)
        |> Enum.map(&create_post(&1, url))

      {:ok,
       %{
         source_platform: "rss",
         source_url: url,
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

  def extract_entries(xml) do
    items = scan_blocks(xml, "item")
    entries = scan_blocks(xml, "entry")

    (items ++ entries)
    |> Enum.map(&parse_entry/1)
    |> Enum.reject(&is_nil/1)
  end

  defp read_feed(opts) do
    cond do
      xml = Keyword.get(opts, :xml) ->
        {:ok, xml}

      url = Keyword.get(opts, :url) ->
        case Req.get(url, receive_timeout: 15_000) do
          {:ok, %{status: status, body: body}} when status in 200..299 -> {:ok, body}
          {:ok, %{status: status}} -> {:error, {:source_unavailable, status}}
          {:error, reason} -> {:error, {:source_unavailable, reason}}
        end

      true ->
        {:error, :missing_feed_source}
    end
  end

  defp scan_blocks(xml, tag) do
    Regex.scan(~r/<#{tag}\b[^>]*>(.*?)<\/#{tag}>/isu, xml, capture: :all_but_first)
    |> List.flatten()
  end

  defp parse_entry(block) do
    title = text_tag(block, "title")
    url = link_for(block)

    if blank?(title) and blank?(url) do
      nil
    else
      %{
        title: title || url || "RSS item",
        summary:
          text_tag(block, "description") || text_tag(block, "summary") ||
            text_tag(block, "content"),
        url: url,
        published_at:
          parse_date(
            text_tag(block, "pubDate") || text_tag(block, "updated") ||
              text_tag(block, "published")
          ),
        author_name: text_tag(block, "author") || text_tag(block, "dc:creator") || "RSS Source"
      }
    end
  end

  defp create_post(entry, source_url) do
    attrs = %{
      "title" => entry.title,
      "summary" => entry.summary || "Imported RSS/Atom feed item.",
      "body" => entry.summary,
      "url" => entry.url,
      "source_name" => "RSS",
      "source_url" => entry.url || source_url,
      "post_type" => "system_news",
      "author_type" => "system",
      "author_name" => entry.author_name,
      "status" => "published",
      "published_at" => entry.published_at || DateTime.utc_now() |> DateTime.truncate(:second),
      "media_type" => "link",
      "media_url" => entry.url,
      "tags" => ["rss", "external"],
      "source_platform" => "rss",
      "metadata" => %{
        "source_platform" => "rss",
        "source_feed_url" => source_url,
        "source_confidence" => "rss_import"
      }
    }

    case Feed.create_post(attrs) do
      {:ok, post} ->
        {:ok, post}

      {:error, changeset} ->
        if duplicate_slug?(changeset), do: {:skipped, entry.url}, else: {:error, changeset}
    end
  end

  defp text_tag(block, tag) do
    case Regex.run(~r/<#{tag}\b[^>]*>(.*?)<\/#{tag}>/isu, block, capture: :all_but_first) do
      [value] -> value |> strip_cdata() |> strip_html() |> html_decode() |> String.trim()
      _ -> nil
    end
    |> blank_to_nil()
  end

  defp link_for(block) do
    text_tag(block, "link") ||
      case Regex.run(~r/<link\b[^>]*href=["']([^"']+)["'][^>]*\/?>/isu, block,
             capture: :all_but_first
           ) do
        [href] -> href
        _ -> nil
      end
      |> blank_to_nil()
  end

  defp parse_date(nil), do: nil

  defp parse_date(value) do
    with {:error, _} <- DateTime.from_iso8601(value),
         {:error, _} <- parse_rfc1123(value) do
      nil
    else
      {:ok, datetime, _offset} -> DateTime.truncate(datetime, :second)
      {:ok, datetime} -> DateTime.truncate(datetime, :second)
    end
  end

  defp parse_rfc1123(_value), do: {:error, :invalid_date}

  defp strip_cdata(value),
    do: value |> String.replace(~r/^\s*<!\[CDATA\[/, "") |> String.replace(~r/\]\]>\s*$/, "")

  defp strip_html(value), do: String.replace(value, ~r/<[^>]+>/u, " ")

  defp html_decode(value) do
    value
    |> String.replace("&amp;", "&")
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&quot;", "\"")
    |> String.replace("&#39;", "'")
  end

  defp blank?(value), do: value in [nil, ""]
  defp blank_to_nil(value) when value in [nil, ""], do: nil
  defp blank_to_nil(value), do: value

  defp duplicate_slug?(changeset) do
    Enum.any?(changeset.errors, fn
      {:slug, {_message, opts}} -> opts[:constraint] == :unique
      _ -> false
    end)
  end
end
