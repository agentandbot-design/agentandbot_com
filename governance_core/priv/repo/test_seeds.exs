alias GovernanceCore.Payment.Payments
alias GovernanceCore.Repo

service = case Payments.get_service_by_slug("icon-generator") do
  nil ->
    IO.puts("Creating icon-generator service...")
    {:ok, s} = Payments.create_service(%{
      name: "Icon Generator",
      slug: "icon-generator",
      active: true,
      owner_wallet: "0x34691456184C0CcD9E5c18A9E383637651aA146F"
    })
    s
  s -> s
end

mock_wallet = "0x1234567890123456789012345678901234567890"
case Payments.get_subscription_by_wallet_and_service(mock_wallet, service.id) do
  nil ->
    IO.puts("Creating subscription for mock wallet...")
    {:ok, sub} = Payments.find_or_create_subscription(service.id, mock_wallet)
    # Add credits
    GovernanceCore.Payment.Credits.add_credits(sub.id, 100)
  _sub ->
    IO.puts("Subscription already exists.")
end
