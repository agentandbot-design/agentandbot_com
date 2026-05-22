alias GovernanceCore.Repo
alias GovernanceCore.Personas.Persona
alias EnyPay.Context

IO.puts "Seeding ENY PAY Specialist Agent (Aura)..."

# 1. Create or Update the IconMaster Persona
aura_attrs = %{
  name: "Aura",
  role: "ENY PAY Brand Architect",
  description: "Specialized in Harezm Ecosystem branding (v7.1). Expert at generating and vectorizing surrealist icons using ENY PAY credits.",
  category: "Professional Services",
  type: "designer_ai",
  sub_type: "bot",
  access_group: "internal",
  status: "active",
  skills: ["icon_generation", "svg_vectorization", "eny_pay_management", "brand_consistency"],
  metadata: %{
    "service_slug" => "icon-generator",
    "primary_color" => "#D0FD17",
    "protocol" => "ABL.ONE/1.0"
  },
  trust_score: 100
}

case Repo.get_by(Persona, name: "Aura") do
  nil ->
    GovernanceCore.Agents.create_agent(aura_attrs)
    IO.puts "Successfully created Aura persona."
  persona ->
    GovernanceCore.Agents.update_agent(persona, aura_attrs)
    IO.puts "Successfully updated Aura persona."
end

IO.puts "Agent seeding complete."
