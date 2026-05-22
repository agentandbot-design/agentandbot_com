defmodule GovernanceCoreWeb.Api.CreditController do
  use GovernanceCoreWeb, :controller

  alias GovernanceCore.Marketplace

  def show(conn, %{"account_id" => account_id}) do
    json(conn, %{
      data: %{
        account_id: account_id,
        available_credits: Marketplace.available_credits(account_id)
      }
    })
  end

  def adjust(conn, %{"account_id" => account_id, "amount_credits" => amount}) do
    case Marketplace.adjust_credits(account_id, parse_int(amount), %{"source" => "api_adjustment"}) do
      {:ok, _entry} ->
        json(conn, %{
          data: %{
            account_id: account_id,
            available_credits: Marketplace.available_credits(account_id)
          }
        })

      {:error, changeset} ->
        conn
        |> put_status(:unprocessable_entity)
        |> json(%{error: "Credit adjustment failed", details: inspect(changeset.errors)})
    end
  end

  def adjust(conn, _params) do
    conn
    |> put_status(:unprocessable_entity)
    |> json(%{error: "Missing required fields: account_id, amount_credits"})
  end

  defp parse_int(value) when is_integer(value), do: value
  defp parse_int(value) when is_binary(value), do: String.to_integer(value)
end
