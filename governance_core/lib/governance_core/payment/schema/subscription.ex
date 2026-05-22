defmodule GovernanceCore.Payment.Subscription do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "payment_subscriptions" do
    field :buyer_wallet, :string
    field :api_key, Ecto.UUID
    field :credits_remaining, :integer, default: 0

    belongs_to :service, GovernanceCore.Payment.Service

    timestamps()
  end

  def changeset(subscription, attrs) do
    subscription
    |> cast(attrs, [:buyer_wallet, :api_key, :credits_remaining, :service_id])
    |> validate_required([:buyer_wallet, :api_key, :service_id])
    |> unique_constraint(:api_key)
  end
end
