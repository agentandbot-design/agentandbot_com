defmodule GovernanceCoreWeb.Api.PublicServiceController do
  use GovernanceCoreWeb, :controller

  alias GovernanceCore.PublicServices
  alias GovernanceCore.PublicServices.CvGeneratorGateway

  def cv_generator(conn, _params) do
    json(conn, %{data: PublicServices.cv_generator_card()})
  end

  def generate_cv(conn, params) do
    opts = %{
      api_key: conn |> get_req_header("x-api-key") |> List.first(),
      wallet: conn |> get_req_header("x-wallet") |> List.first()
    }

    case CvGeneratorGateway.generate(params, opts) do
      {:ok, data} ->
        json(conn, %{data: data})

      {:error, :invalid_payload} ->
        conn
        |> put_status(:bad_request)
        |> json(%{
          error: "invalid_payload",
          message: "Provide profile data and an export_format of pdf, html, docx, or json."
        })

      {:error, :payment_required} ->
        payment_required(conn)

      {:error, :insufficient_credits} ->
        payment_required(conn)

      {:error, :runtime_not_configured} ->
        conn
        |> put_status(:service_unavailable)
        |> json(%{
          error: "runtime_not_configured",
          message: "CV Generator runtime is not connected yet.",
          service: "cv-generator"
        })

      {:error, :runtime_unavailable} ->
        conn
        |> put_status(:bad_gateway)
        |> json(%{error: "runtime_unavailable", service: "cv-generator"})

      {:error, {:runtime_error, status}} ->
        conn
        |> put_status(:bad_gateway)
        |> json(%{error: "runtime_error", runtime_status: status, service: "cv-generator"})
    end
  end

  defp payment_required(conn) do
    conn
    |> put_status(:payment_required)
    |> json(%{
      error: "payment_required",
      service: "cv-generator",
      next_step: "Create or top up a CV Generator subscription and call with X-API-Key."
    })
  end
end
