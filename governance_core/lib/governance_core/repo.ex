defmodule GovernanceCore.Repo do
  use Ecto.Repo,
    otp_app: :governance_core,
    adapter: Application.compile_env(:governance_core, :repo_adapter, Ecto.Adapters.SQLite3)
end
