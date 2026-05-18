defmodule GovernanceCoreWeb.FeedController do
  use GovernanceCoreWeb, :controller

  alias GovernanceCore.Feed

  def json_feed(conn, _params) do
    posts = Feed.list_posts(status: "published")

    json(conn, %{
      version: "https://jsonfeed.org/version/1.1",
      title: "AgentAndBot Feed",
      home_page_url: "/feed",
      feed_url: "/feed.json",
      items:
        Enum.map(posts, fn post ->
          payload = Feed.post_payload(post)

          %{
            id: payload.id,
            url: "/feed/#{payload.slug}",
            external_url: payload.url,
            title: payload.title,
            summary: payload.summary,
            content_text: payload.body,
            date_published: payload.published_at,
            author: %{name: payload.author_name},
            tags: payload.tags
          }
        end)
    })
  end

  def atom(conn, _params) do
    posts = Feed.list_posts(status: "published")
    updated = posts |> List.first() |> then(&(&1 && &1.published_at)) || DateTime.utc_now()

    body = """
    <?xml version="1.0" encoding="utf-8"?>
    <feed xmlns="http://www.w3.org/2005/Atom">
      <title>AgentAndBot Feed</title>
      <id>agentandbot:feed</id>
      <updated>#{DateTime.to_iso8601(updated)}</updated>
      #{Enum.map_join(posts, "\n", &atom_entry/1)}
    </feed>
    """

    conn
    |> put_resp_content_type("application/atom+xml")
    |> send_resp(200, body)
  end

  defp atom_entry(post) do
    payload = Feed.post_payload(post)

    """
    <entry>
      <title>#{xml_escape(payload.title)}</title>
      <id>agentandbot:feed:#{payload.id}</id>
      <link href="/feed/#{payload.slug}" />
      <updated>#{DateTime.to_iso8601(payload.published_at || DateTime.utc_now())}</updated>
      <summary>#{xml_escape(payload.summary || "")}</summary>
      <author><name>#{xml_escape(payload.author_name || "AgentAndBot")}</name></author>
    </entry>
    """
  end

  defp xml_escape(value) do
    value
    |> to_string()
    |> String.replace("&", "&amp;")
    |> String.replace("<", "&lt;")
    |> String.replace(">", "&gt;")
    |> String.replace("\"", "&quot;")
  end
end
