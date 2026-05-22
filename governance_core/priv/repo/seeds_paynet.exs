alias EnyPay.Context
alias EnyPay.Service
alias GovernanceCore.Repo

IO.puts "Seeding ENY PAY services..."

# 1. Icon Generator Service
icon_service = %{
  name: "Icon Generator (Surrealist)",
  slug: "icon-generator",
  owner_wallet: "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
  endpoint_url: "https://api.agentandbot.com/v1/generate-icon",
  price_per_request: 1,
  active: true
}

case Context.create_service(icon_service) do
  {:ok, _} -> IO.puts "Successfully created 'icon-generator' service."
  {:error, _} -> IO.puts "Service 'icon-generator' already exists or error."
end

# 2. Text-to-Image Service
img_service = %{
  name: "Pro Image Generation",
  slug: "image-gen",
  owner_wallet: "0x742d35Cc6634C0532925a3b844Bc454e4438f44e",
  endpoint_url: "https://api.agentandbot.com/v1/generate-image",
  price_per_request: 5,
  active: true
}

case Context.create_service(img_service) do
  {:ok, _} -> IO.puts "Successfully created 'image-gen' service."
  {:error, _} -> IO.puts "Service 'image-gen' already exists or error."
end

IO.puts "Seeding complete."
