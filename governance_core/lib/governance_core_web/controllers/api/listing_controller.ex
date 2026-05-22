defmodule GovernanceCoreWeb.Api.ListingController do
  use GovernanceCoreWeb, :controller

  alias GovernanceCore.Marketplace
  alias GovernanceCore.Marketplace.AgentListing

  def index(conn, _params) do
    listings = Marketplace.list_listings()
    json(conn, %{data: Enum.map(listings, &listing_payload/1)})
  end

  def show(conn, %{"id" => id}) do
    case Marketplace.get_listing(id) do
      nil -> error(conn, :not_found, "Listing not found")
      listing -> json(conn, %{data: listing_payload(listing)})
    end
  end

  def create(conn, params) do
    case Marketplace.create_listing(params) do
      {:ok, listing} ->
        conn
        |> put_status(:created)
        |> json(%{data: listing_payload(listing), message: "Listing saved as draft"})

      {:error, changeset} ->
        changeset_error(conn, changeset)
    end
  end

  def update(conn, %{"id" => id} = params) do
    case Marketplace.get_listing(id) do
      nil ->
        error(conn, :not_found, "Listing not found")

      listing ->
        case Marketplace.update_listing(listing, params) do
          {:ok, listing} -> json(conn, %{data: listing_payload(listing)})
          {:error, changeset} -> changeset_error(conn, changeset)
        end
    end
  end

  def publish(conn, %{"id" => id}) do
    case Marketplace.publish_listing(id) do
      {:ok, listing} ->
        json(conn, %{data: listing_payload(listing), message: "Listing published"})

      {:error, :listing_not_found} ->
        error(conn, :not_found, "Listing not found")

      {:error, changeset} ->
        changeset_error(conn, changeset)
    end
  end

  def hire(conn, %{"id" => id} = params) do
    case Marketplace.hire_listing(id, params) do
      {:ok, task} ->
        conn
        |> put_status(:accepted)
        |> json(%{data: %{task_id: task.id, status: task.status}, message: "Task escrowed"})

      {:error, reason} ->
        marketplace_error(conn, reason)
    end
  end

  def rent(conn, %{"id" => id} = params) do
    case Marketplace.rent_listing(id, params) do
      {:ok, contract} ->
        conn
        |> put_status(:created)
        |> json(%{
          data: %{contract_id: contract.id, status: contract.status},
          message: "Rental active"
        })

      {:error, reason} ->
        marketplace_error(conn, reason)
    end
  end

  def provider(conn, %{"id" => id}) do
    case Marketplace.provider_redirect(id) do
      {:ok, payload} -> json(conn, %{data: payload})
      {:error, reason} -> marketplace_error(conn, reason)
    end
  end

  def listing_payload(%AgentListing{} = listing) do
    %{
      id: listing.id,
      persona_id: listing.persona_id,
      seller_id: listing.seller_id,
      title: listing.title,
      summary: listing.summary,
      source_type: listing.source_type,
      fulfillment_mode: listing.fulfillment_mode,
      hosting_mode: listing.hosting_mode,
      status: listing.status,
      runtime_kind: listing.runtime_kind,
      provider_id: listing.provider_id,
      provider_url: listing.provider_url,
      external_setup_url: listing.external_setup_url,
      task_price_credits: listing.task_price_credits,
      rental_price_credits: listing.rental_price_credits,
      rental_period: listing.rental_period,
      configuration_schema: listing.configuration_schema,
      default_configuration: listing.default_configuration,
      required_skills: listing.required_skills || [],
      standards: listing.standards || [],
      profile: safe_profile(listing.metadata)
    }
  end

  defp safe_profile(%{"kadro_profile" => profile}) when is_map(profile) do
    Map.take(profile, [
      "p_no",
      "category",
      "age",
      "gender",
      "country",
      "city",
      "profession",
      "personality",
      "content",
      "social",
      "email",
      "phone",
      "telegram",
      "whatsapp",
      "height_cm",
      "weight_kg",
      "instagram",
      "tiktok",
      "linkedin",
      "youtube",
      "x",
      "facebook",
      "headshot_url",
      "full_body_url",
      "cv_url"
    ])
  end

  defp safe_profile(_metadata), do: nil

  defp marketplace_error(conn, :listing_not_found),
    do: error(conn, :not_found, "Listing not found")

  defp marketplace_error(conn, :agent_not_found),
    do: error(conn, :not_found, "Listing has no connected agent")

  defp marketplace_error(conn, :provider_url_missing),
    do: error(conn, :unprocessable_entity, "Provider URL missing")

  defp marketplace_error(conn, :fulfillment_not_available),
    do: error(conn, :unprocessable_entity, "Action not available for this listing")

  defp marketplace_error(conn, :insufficient_credits),
    do: error(conn, :payment_required, "Insufficient internal credits")

  defp marketplace_error(conn, %Ecto.Changeset{} = changeset),
    do: changeset_error(conn, changeset)

  defp marketplace_error(conn, reason), do: error(conn, :unprocessable_entity, inspect(reason))

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
