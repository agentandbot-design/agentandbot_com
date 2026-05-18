defmodule GovernanceCoreWeb.Api.FeedController do
  use GovernanceCoreWeb, :controller

  alias GovernanceCore.Feed

  def index(conn, params) do
    posts =
      Feed.list_posts(
        status: Map.get(params, "status", "published"),
        post_type: Map.get(params, "post_type", "all")
      )

    json(conn, %{data: Enum.map(posts, &Feed.post_payload/1)})
  end

  def show(conn, %{"id" => id}) do
    case Feed.get_post(id) do
      nil -> error(conn, :not_found, "Feed post not found")
      post -> json(conn, %{data: Feed.post_payload(post)})
    end
  end

  def create(conn, params) do
    case Feed.create_post(params) do
      {:ok, post} ->
        conn
        |> put_status(:created)
        |> json(%{data: Feed.post_payload(post), message: "Feed post saved as draft"})

      {:error, changeset} ->
        changeset_error(conn, changeset)
    end
  end

  def publish(conn, %{"id" => id}) do
    case Feed.publish_post(id) do
      {:ok, post} -> json(conn, %{data: Feed.post_payload(post), message: "Feed post published"})
      {:error, :post_not_found} -> error(conn, :not_found, "Feed post not found")
      {:error, changeset} -> changeset_error(conn, changeset)
    end
  end

  def react(conn, %{"id" => id} = params) do
    case Feed.rate_post(id, params) do
      {:ok, _reaction} ->
        post = Feed.get_post(id)
        json(conn, %{data: Feed.post_payload(post), message: "Reaction saved"})

      {:error, :post_not_found} ->
        error(conn, :not_found, "Feed post not found")

      {:error, changeset} ->
        changeset_error(conn, changeset)
    end
  end

  def import_awesome(conn, params) do
    opts =
      case Map.get(params, "readme") do
        readme when is_binary(readme) and readme != "" -> [readme: readme]
        _ -> []
      end

    case Feed.import_awesome_llm_apps(opts) do
      {:ok, result} -> json(conn, %{data: result})
      {:error, reason} -> error(conn, :bad_gateway, inspect(reason))
    end
  end

  defp changeset_error(conn, changeset) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: "Validation failed", details: inspect(changeset.errors)})
  end

  defp error(conn, status, message) do
    conn
    |> put_status(status)
    |> json(%{error: message})
  end
end
