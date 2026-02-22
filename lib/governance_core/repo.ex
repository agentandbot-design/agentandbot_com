defmodule GovernanceCore.Repo do
  use Ecto.Repo,
    otp_app: :governance_core,
    adapter: Ecto.Adapters.Postgres
end
