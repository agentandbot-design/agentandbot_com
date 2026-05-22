defmodule GovernanceCore.Repo.Migrations.CreatePaymentServices do
  use Ecto.Migration

  def change do
    create table(:payment_services, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :name, :string, null: false
      add :slug, :string, null: false
      add :owner_wallet, :string, null: false
      add :endpoint_url, :string
      add :price_per_request, :integer
      add :active, :boolean, default: true, null: false

      timestamps()
    end

    create unique_index(:payment_services, [:slug])
  end
end
