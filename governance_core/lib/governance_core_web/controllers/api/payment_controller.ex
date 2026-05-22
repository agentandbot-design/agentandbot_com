defmodule GovernanceCoreWeb.Api.PaymentController do
  use GovernanceCoreWeb, :controller
  alias GovernanceCore.Payment.{Payments, Blockchain, Credits}

  @packages %{
    "starter" => %{credits: 10, price: 0.5},
    "basic" => %{credits: 50, price: 2.0},
    "pro" => %{credits: 150, price: 5.0}
  }

  def submit(conn, %{
        "tx_hash" => tx_hash,
        "chain" => chain,
        "service_slug" => slug,
        "buyer_wallet" => buyer_wallet,
        "package" => package_name
      }) do
    service = Payments.get_service_by_slug(slug)
    package = Map.get(@packages, package_name)

    cond do
      is_nil(service) ->
        conn |> put_status(:not_found) |> json(%{error: "Service not found"})

      is_nil(package) ->
        conn |> put_status(:bad_request) |> json(%{error: "Invalid package"})

      Payments.get_transaction_by_hash(tx_hash) ->
        conn |> put_status(:conflict) |> json(%{error: "Transaction already processed"})

      true ->
        case Blockchain.verify_transaction(tx_hash, chain, service.owner_wallet, package.price) do
          {:ok, verified_data} ->
            {:ok, sub} = Payments.find_or_create_subscription(service.id, buyer_wallet)

            {:ok, _tx} =
              Payments.create_transaction(%{
                service_id: service.id,
                subscription_id: sub.id,
                buyer_wallet: buyer_wallet,
                amount_usdc: verified_data.amount,
                tx_hash: tx_hash,
                chain: chain,
                status: "confirmed",
                credits_added: package.credits
              })

            # Add credits to the subscription
            {:ok, credits_remaining} = Credits.add_credits(sub.id, package.credits)

            json(conn, %{
              "api_key" => sub.api_key,
              "credits_added" => package.credits,
              "credits_remaining" => credits_remaining,
              "package" => package_name,
              "next_step" => "Use api_key in X-API-Key header"
            })

          {:error, reason} ->
            conn
            |> put_status(:bad_request)
            |> json(%{error: "Verification failed", reason: reason})
        end
    end
  end
end
