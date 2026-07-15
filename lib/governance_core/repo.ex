defmodule GovernanceCore.Repo do
  adapter =
    case System.get_env("DATABASE_URL") do
      nil -> Ecto.Adapters.SQLite3
      _   -> Ecto.Adapters.Postgres
    end

  use Ecto.Repo,
    otp_app: :governance_core,
    adapter: adapter
end
