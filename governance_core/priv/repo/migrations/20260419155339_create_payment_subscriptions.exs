defmodule GovernanceCore.Repo.Migrations.CreatePaymentSubscriptions do
  use Ecto.Migration

  def change do
    create table(:payment_subscriptions, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :service_id, references(:payment_services, type: :binary_id, on_delete: :nothing),
        null: false

      add :buyer_wallet, :string, null: false
      add :api_key, :uuid, null: false
      add :credits_remaining, :integer, default: 0, null: false

      timestamps()
    end

    create index(:payment_subscriptions, [:service_id])
    create unique_index(:payment_subscriptions, [:api_key])
  end
end
