defmodule GovernanceCore.Payment.Transaction do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "payment_transactions" do
    field :buyer_wallet, :string
    field :amount_usdc, :decimal
    field :tx_hash, :string
    field :chain, :string
    # pending/confirmed/failed
    field :status, :string, default: "pending"
    field :credits_added, :integer

    belongs_to :service, GovernanceCore.Payment.Service
    belongs_to :subscription, GovernanceCore.Payment.Subscription

    timestamps()
  end

  def changeset(transaction, attrs) do
    transaction
    |> cast(attrs, [
      :buyer_wallet,
      :amount_usdc,
      :tx_hash,
      :chain,
      :status,
      :credits_added,
      :service_id,
      :subscription_id
    ])
    |> validate_required([
      :buyer_wallet,
      :amount_usdc,
      :tx_hash,
      :chain,
      :service_id,
      :subscription_id
    ])
    |> unique_constraint(:tx_hash)
  end
end
