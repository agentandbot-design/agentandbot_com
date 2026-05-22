defmodule GovernanceCore.Repo.Migrations.CreatePaymentTransactions do
  use Ecto.Migration

  def change do
    create table(:payment_transactions, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :service_id, references(:payment_services, type: :binary_id, on_delete: :nothing),
        null: false

      add :subscription_id,
          references(:payment_subscriptions, type: :binary_id, on_delete: :nothing)

      add :buyer_wallet, :string
      add :amount_usdc, :decimal
      add :tx_hash, :string, null: false
      add :chain, :string, null: false
      add :status, :string, default: "pending", null: false
      add :credits_added, :integer

      timestamps()
    end

    create index(:payment_transactions, [:service_id])
    create index(:payment_transactions, [:subscription_id])
    create unique_index(:payment_transactions, [:tx_hash])
  end
end
