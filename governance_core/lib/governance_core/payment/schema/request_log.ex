defmodule GovernanceCore.Payment.RequestLog do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema "payment_request_logs" do
    # success/rejected
    field :status, :string

    belongs_to :subscription, GovernanceCore.Payment.Subscription
    belongs_to :service, GovernanceCore.Payment.Service

    timestamps(updated_at: false)
  end

  def changeset(request_log, attrs) do
    request_log
    |> cast(attrs, [:status, :subscription_id, :service_id])
    |> validate_required([:status, :subscription_id, :service_id])
  end
end
