alias GovernanceCore.Repo
alias GovernanceCore.Personas.Persona
alias EnyPay.Service
alias EnyPay.Subscription

IO.puts "[SEEDS] Populating ENY PAY Core Data..."

# 1. Aura Persona (Financial Manager)
aura_attrs = %{
  name: "Aura",
  role: "Financial Tasker",
  type: "agentzero",
  sub_type: "bot",
  access_group: "internal",
  status: "active",
  trust_score: 100,
  description: "The financial brain of the ecosystem. Managed by ENY PAY.",
  category: "Finance",
  skills: ["USDC processing", "Subscription management", "Blockchain verification"],
  owner: "0x34691456184C0CcD9E5c18A9E383637651aA146F", # Aura's wallet
  balance_cents: 0
}

case Repo.get_by(Persona, name: "Aura") do
  nil ->
    IO.puts "[SEEDS] Creating Persona: Aura"
    %Persona{} |> Persona.changeset(aura_attrs) |> Repo.insert!()
  existing ->
    IO.puts "[SEEDS] Persona Aura already exists. Updating..."
    existing |> Persona.changeset(aura_attrs) |> Repo.update!()
end

# 2. Icon Generator Service
service_attrs = %{
  name: "SVG Icon Generator",
  slug: "icon-generator",
  owner_wallet: "0x34691456184C0CcD9E5c18A9E383637651aA146F", # Managed by Aura
  endpoint_url: "http://localhost:4323/tools/svg-vectorizer",
  price_per_request: 1, # 1 Credit
  active: true
}

case Repo.get_by(Service, slug: "icon-generator") do
  nil ->
    IO.puts "[SEEDS] Creating Service: SVG Icon Generator"
    %Service{} |> Service.changeset(service_attrs) |> Repo.insert!()
  existing ->
    IO.puts "[SEEDS] Service icon-generator already exists. Updating..."
    existing |> Service.changeset(service_attrs) |> Repo.update!()
end

# 3. Test Subscription (Optional but helps testing)
test_wallet = "0x000000000000000000000000000000000000dEaD"
service = Repo.get_by(Service, slug: "icon-generator")

case Repo.get_by(Subscription, buyer_wallet: test_wallet, service_id: service.id) do
  nil ->
    IO.puts "[SEEDS] Creating Test Subscription for #{test_wallet}"
    %Subscription{}
    |> Subscription.changeset(%{
      service_id: service.id,
      buyer_wallet: test_wallet,
      api_key: "550e8400-e29b-41d4-a716-446655440000",
      credits_remaining: 10
    })
    |> Repo.insert!()
  _existing ->
    IO.puts "[SEEDS] Test subscription already exists."
end

IO.puts "[SEEDS] ENY PAY seeding complete."
