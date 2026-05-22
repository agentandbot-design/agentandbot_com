defmodule GovernanceCore.Payment.Payments do
  @moduledoc """
  Context module for managing AgentAndBot payment data.
  """
  import Ecto.Query
  alias GovernanceCore.Repo
  alias GovernanceCore.Payment.{Service, Subscription, Transaction, RequestLog}

  # --- Services ---

  def list_services do
    Repo.all(from(s in Service, where: s.active == true))
  end

  def get_service_by_slug(slug) do
    Repo.get_by(Service, slug: slug, active: true)
  end

  def create_service(attrs) do
    %Service{}
    |> Service.changeset(attrs)
    |> Repo.insert()
  end

  def upsert_service(attrs) do
    attrs =
      attrs
      |> stringify_keys()
      |> Map.put_new("active", true)

    case get_service_by_slug(attrs["slug"]) do
      nil ->
        create_service(attrs)

      service ->
        service
        |> Service.changeset(attrs)
        |> Repo.update()
    end
  end

  # --- Subscriptions ---

  def get_subscription_by_api_key(api_key) do
    Repo.get_by(Subscription, api_key: api_key)
    |> Repo.preload(:service)
  end

  def get_subscription_by_wallet_and_service(wallet, service_id) do
    Repo.get_by(Subscription, buyer_wallet: wallet, service_id: service_id)
    |> Repo.preload(:service)
  end

  def find_or_create_subscription(service_id, buyer_wallet) do
    case Repo.get_by(Subscription, service_id: service_id, buyer_wallet: buyer_wallet) do
      nil ->
        %Subscription{}
        |> Subscription.changeset(%{
          service_id: service_id,
          buyer_wallet: buyer_wallet,
          credits_remaining: 0,
          api_key: Ecto.UUID.generate()
        })
        |> Repo.insert()

      sub ->
        {:ok, sub}
    end
  end

  # --- Transactions ---

  def create_transaction(attrs) do
    %Transaction{}
    |> Transaction.changeset(attrs)
    |> Repo.insert()
  end

  def get_transaction_by_hash(hash) do
    Repo.get_by(Transaction, tx_hash: hash)
  end

  def list_recent_transactions(limit \\ 20) do
    from(t in Transaction,
      order_by: [desc: t.inserted_at],
      limit: ^limit
    )
    |> Repo.all()
  end

  def sum_confirmed_amount do
    from(t in Transaction,
      where: t.status == "confirmed",
      select: sum(t.amount_usdc)
    )
    |> Repo.one()
    |> case do
      nil -> Decimal.new(0)
      val -> val
    end
  end

  def count_active_subscriptions do
    from(s in Subscription,
      where: s.credits_remaining > 0,
      select: count(s.id)
    )
    |> Repo.one()
  end

  # --- Requests ---

  def log_request(attrs) do
    %RequestLog{}
    |> RequestLog.changeset(attrs)
    |> Repo.insert()
  end

  def count_requests_today do
    today = NaiveDateTime.utc_now() |> NaiveDateTime.to_date()
    start_of_day = NaiveDateTime.new!(today, ~T[00:00:00])
    end_of_day = NaiveDateTime.add(start_of_day, 1, :day)

    from(l in RequestLog,
      where: l.inserted_at >= ^start_of_day and l.inserted_at < ^end_of_day,
      select: count(l.id)
    )
    |> Repo.one()
  end

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn {key, value} -> {to_string(key), value} end)
  end
end
