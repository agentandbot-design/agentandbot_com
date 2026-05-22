defmodule GovernanceCore.Repo.Migrations.CreatePaymentRequestLogs do
  use Ecto.Migration

  def change do
    create table(:payment_request_logs, primary_key: false) do
      add :id, :binary_id, primary_key: true

      add :subscription_id,
          references(:payment_subscriptions, type: :binary_id, on_delete: :nothing), null: false

      add :service_id, references(:payment_services, type: :binary_id, on_delete: :nothing),
        null: false

      add :status, :string, null: false

      add :inserted_at, :utc_datetime, null: false
    end

    create index(:payment_request_logs, [:subscription_id])
    create index(:payment_request_logs, [:service_id])
  end
end
