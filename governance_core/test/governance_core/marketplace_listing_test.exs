defmodule GovernanceCore.MarketplaceListingTest do
  use GovernanceCore.DataCase, async: true

  alias GovernanceCore.Marketplace
  alias GovernanceCore.Personas.Persona
  alias GovernanceCore.Repo

  setup do
    agent =
      %Persona{}
      |> Persona.changeset(%{
        name: "Listing Agent",
        sub_type: "bot",
        access_group: "external",
        status: "active",
        owner: "seller",
        runtime_kind: "hermes",
        skills: ["deliver_artifact"]
      })
      |> Repo.insert!()

    Marketplace.upsert_policy(%{persona_id: agent.id, allowed_skills: ["deliver_artifact"]})
    Marketplace.adjust_credits("buyer", 200)

    {:ok, agent: agent}
  end

  test "creates and publishes a listing", %{agent: agent} do
    {:ok, listing} =
      Marketplace.create_listing(%{
        persona_id: agent.id,
        seller_id: "seller",
        title: "Draft Listing",
        runtime_kind: "hermes",
        required_skills: "deliver_artifact",
        standards: "MCP, A2A"
      })

    assert listing.status == "draft"
    assert {:ok, published} = Marketplace.publish_listing(listing.id)
    assert published.status == "published"
  end

  test "hire listing creates escrowed task", %{agent: agent} do
    {:ok, listing} = published_listing(agent)

    assert {:ok, task} =
             Marketplace.hire_listing(listing.id, %{
               "created_by" => "buyer",
               "title" => "Make artifact",
               "required_skill" => "deliver_artifact"
             })

    assert task.status == "escrowed"
    assert Marketplace.available_credits("buyer") == 195
  end

  test "rent listing creates active contract", %{agent: agent} do
    {:ok, listing} = published_listing(agent)

    assert {:ok, contract} = Marketplace.rent_listing(listing.id, %{"created_by" => "buyer"})
    assert contract.status == "active"
    assert Marketplace.available_credits("buyer") == 150
  end

  test "provider listing returns redirect without escrow" do
    {:ok, listing} =
      Marketplace.create_listing(%{
        seller_id: "provider",
        title: "Provider Listing",
        source_type: "third_party_provider",
        fulfillment_mode: "both",
        hosting_mode: "external_provider",
        runtime_kind: "custom_webhook",
        provider_url: "https://provider.example/agent",
        status: "published"
      })

    assert {:ok, redirect} = Marketplace.provider_redirect(listing.id)
    assert redirect.url == "https://provider.example/agent"
  end

  defp published_listing(agent) do
    Marketplace.create_listing(%{
      persona_id: agent.id,
      seller_id: "seller",
      title: "Published Listing",
      runtime_kind: "hermes",
      status: "published",
      task_price_credits: 5,
      rental_price_credits: 50,
      required_skills: ["deliver_artifact"],
      standards: ["MCP"]
    })
  end
end
