# priv/repo/seeds_payment.exs

alias GovernanceCore.Repo
alias GovernanceCore.Payment.Payments
alias GovernanceCore.PublicServices

IO.puts "[SEEDS] Populating AgentAndBot Core Data..."

# 1. Create a sample service
case Payments.get_service_by_slug("icon-generator") do
  nil ->
    IO.puts "[SEEDS] Creating Service: icon-generator"
    Payments.create_service(%{
      name: "SVG Icon Generator",
      slug: "icon-generator",
      owner_wallet: "0x34691456184C0CcD9E5c18A9E383637651aA146F",
      endpoint_url: "http://localhost:4323/tools/svg-vectorizer",
      price_per_request: 5,
      active: true
    })
  service ->
    IO.puts "[SEEDS] Service already exists: #{service.slug}"
end

IO.puts "[SEEDS] Payment seeding complete."

case PublicServices.ensure_cv_generator_registered() do
  {:ok, service} -> IO.puts "[SEEDS] Service ready: #{service.slug}"
  {:error, reason} -> IO.inspect(reason, label: "[SEEDS] CV Generator error")
end
