defmodule GovernanceCoreWeb.Api.ProviderController do
  use GovernanceCoreWeb, :controller

  alias GovernanceCore.Marketplace

  def index(conn, _params) do
    json(conn, %{data: Marketplace.providers()})
  end

  def apps(conn, _params) do
    json(conn, %{
      data: Marketplace.provider_apps(),
      categories: Marketplace.provider_app_categories()
    })
  end

  def rate_app(conn, %{"id" => id} = params) do
    case Marketplace.rate_provider_app(id, params) do
      {:ok, _rating} ->
        json(conn, %{data: Marketplace.get_provider_app(id), message: "Rating saved"})

      {:error, :provider_app_not_found} ->
        conn
        |> put_status(:not_found)
        |> json(%{error: "Provider app not found"})

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Rating could not be saved", details: inspect(changeset.errors)})
    end
  end
end
