defmodule GovernanceCore.PaymentTest do
  use GovernanceCore.DataCase
  alias GovernanceCore.Payment.{Payments, Credits, Blockchain}

  setup do
    # Set mock mode for tests
    System.put_env("MOCK_PAYMENTS", "true")

    service_attrs = %{
      name: "Test Service",
      slug: "test-service",
      owner_wallet: "0x123",
      price_per_request: 5
    }

    {:ok, service} = Payments.create_service(service_attrs)

    on_exit(fn ->
      System.delete_env("MOCK_PAYMENTS")
    end)

    %{service: service}
  end

  test "complete payment and consumption flow", %{service: service} do
    buyer_wallet = "0xBUYER"
    tx_hash = "0xHASH123"

    # 1. Verify blockchain mock works
    assert {:ok, verified} =
             Blockchain.verify_transaction(tx_hash, "base", service.owner_wallet, 0.5)

    assert verified.to == service.owner_wallet

    # 2. Find or create subscription
    {:ok, sub} = Payments.find_or_create_subscription(service.id, buyer_wallet)
    assert sub.credits_remaining == 0

    # 3. Add credits (simulating payment submission)
    {:ok, new_balance} = Credits.add_credits(sub.id, 50)
    assert new_balance == 50

    # 4. Deduct credit (simulating service usage)
    {:ok, remaining} = Credits.deduct_credit(sub.id)
    assert remaining == 49

    # 5. Check request logging
    {:ok, _log} =
      Payments.log_request(%{
        subscription_id: sub.id,
        service_id: service.id,
        status: "success"
      })

    assert Payments.count_requests_today() == 1
  end

  test "insufficient credits deduction", %{service: service} do
    {:ok, sub} = Payments.find_or_create_subscription(service.id, "0xEMPTY")
    assert {:error, :insufficient_credits} = Credits.deduct_credit(sub.id)
  end
end
