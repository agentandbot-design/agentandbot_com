defmodule KadroPlatform.Repo do
  use Ecto.Repo,
    otp_app: :kadro_platform,
    adapter: Ecto.Adapters.SQLite3
end
