defmodule GovernanceCoreWeb.Api.ServiceController do
  use GovernanceCoreWeb, :controller
  alias GovernanceCore.Payment.Payments

  def index(conn, _params) do
    services = Payments.list_services()
    json(conn, %{services: services})
  end

  def create(conn, params) do
    case Payments.create_service(params) do
      {:ok, service} ->
        conn
        |> put_status(:created)
        |> json(service)

      {:error, changeset} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid service data", details: changeset_errors(changeset)})
    end
  end

  defp changeset_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Regex.replace(~r"%{(\w+)}", msg, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
