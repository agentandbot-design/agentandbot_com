defmodule GovernanceCore.Payment.Service do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "payment_services" do
    field :name, :string
    field :slug, :string
    field :owner_wallet, :string
    field :endpoint_url, :string
    # usdc cents
    field :price_per_request, :integer
    field :active, :boolean, default: true

    timestamps()
  end

  def changeset(service, attrs) do
    service
    |> cast(attrs, [:name, :slug, :owner_wallet, :endpoint_url, :price_per_request, :active])
    |> validate_required([:name, :slug, :owner_wallet, :price_per_request])
    |> unique_constraint(:slug)
  end
end
