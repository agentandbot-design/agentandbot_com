defmodule GovernanceCore.Marketplace.CreditLedgerEntry do
  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  @entry_types ~w(adjustment escrow_hold release refund)

  schema "credit_ledger_entries" do
    belongs_to :agent, GovernanceCore.Personas.Persona
    belongs_to :task, GovernanceCore.Marketplace.Task

    field :account_id, :string
    field :entry_type, :string
    field :amount_credits, :integer
    field :metadata, :map, default: %{}

    timestamps(type: :utc_datetime)
  end

  def changeset(entry, attrs) do
    entry
    |> cast(attrs, [:account_id, :agent_id, :task_id, :entry_type, :amount_credits, :metadata])
    |> validate_required([:account_id, :entry_type, :amount_credits])
    |> validate_inclusion(:entry_type, @entry_types)
  end
end
