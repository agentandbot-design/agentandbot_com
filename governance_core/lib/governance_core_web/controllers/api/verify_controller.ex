defmodule GovernanceCoreWeb.Api.VerifyController do
  use GovernanceCoreWeb, :controller
  alias GovernanceCore.Payment.{Payments, Credits}
  require Logger

  def info(conn, %{"slug" => slug}) do
    api_key = get_req_header(conn, "x-api-key") |> List.first()
    wallet = get_req_header(conn, "x-wallet") |> List.first()

    with service when not is_nil(service) <- Payments.get_service_by_slug(slug),
         sub when not is_nil(sub) <- find_subscription(api_key, wallet, service.id) do
      json(conn, %{
        valid: true,
        credits_remaining: sub.credits_remaining,
        service: slug
      })
    else
      nil ->
        render_402(conn, slug)
    end
  end

  def verify(conn, %{"slug" => slug}) do
    api_key = get_req_header(conn, "x-api-key") |> List.first()
    wallet = get_req_header(conn, "x-wallet") |> List.first()

    with service when not is_nil(service) <- Payments.get_service_by_slug(slug),
         sub when not is_nil(sub) <- find_subscription(api_key, wallet, service.id),
         {:ok, credits_remaining} <- Credits.deduct_credit(sub.id) do
      Payments.log_request(%{
        subscription_id: sub.id,
        service_id: service.id,
        status: "success"
      })

      json(conn, %{
        valid: true,
        credits_remaining: credits_remaining,
        service: slug
      })
    else
      nil ->
        # Either service or subscription not found
        render_402(conn, slug)

      {:error, :insufficient_credits} ->
        # Log rejected request
        service = Payments.get_service_by_slug(slug)
        sub = Payments.get_subscription_by_api_key(api_key)

        if sub && service do
          Payments.log_request(%{
            subscription_id: sub.id,
            service_id: service.id,
            status: "rejected"
          })
        end

        render_402(conn, slug)

      err ->
        Logger.error("[VERIFY] Unexpected error for slug #{slug}: #{inspect(err)}")
        render_402(conn, slug)
    end
  end

  # consume is an alias for verify in this billed context
  def consume(conn, params), do: verify(conn, params)

  defp find_subscription(api_key, wallet, service_id) do
    cond do
      api_key -> Payments.get_subscription_by_api_key(api_key)
      wallet -> Payments.get_subscription_by_wallet_and_service(wallet, service_id)
      true -> nil
    end
  end

  defp render_402(conn, slug) do
    service = Payments.get_service_by_slug(slug) || %{name: slug, owner_wallet: "0x..."}

    conn
    |> put_status(:payment_required)
    |> json(%{
      "error" => "Payment Required",
      "service" => service.name,
      "pricing" => [
        %{"package" => "starter", "credits" => 10, "price_usdc" => 0.5},
        %{"package" => "basic", "credits" => 50, "price_usdc" => 2.0},
        %{"package" => "pro", "credits" => 150, "price_usdc" => 5.0}
      ],
      "payment" => %{
        "wallet" => Map.get(service, :owner_wallet, "0x34691456184C0CcD9E5c18A9E383637651aA146F"),
        "chains" => ["base", "arbitrum", "polygon"],
        "token" => "USDC",
        "submit_url" => "https://api.agentandbot.com/api/v1/payments/submit"
      },
      "instructions" => "Send USDC to wallet, POST tx_hash to submit_url",
      "docs" => "https://agentandbot.com/docs/agents",
      "skill" => "https://agentandbot.com/.well-known/agent-skill.md"
    })
  end
end
