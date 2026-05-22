defmodule GovernanceCore.PublicServices.CvGeneratorGateway do
  @moduledoc """
  Gateway contract for the public CV Generator service.

  The gateway validates payment access in AgentAndBot and forwards the request to
  the external runtime only when that runtime is configured.
  """

  alias GovernanceCore.Payment.{Credits, Payments}
  alias GovernanceCore.PublicServices

  @slug "cv-generator"
  @allowed_export_formats ~w(pdf html docx json)
  @allowed_top_level_fields ~w(profile template locale export_format source_site callback_url)

  def generate(params, opts) when is_map(params) and is_map(opts) do
    with {:ok, service} <- ensure_service(),
         {:ok, subscription} <- authorize(service, opts),
         {:ok, payload} <- normalize_payload(params),
         {:ok, runtime_url} <- runtime_generate_url(),
         {:ok, runtime_body} <- forward(runtime_url, payload),
         {:ok, credits_remaining} <- deduct_and_log(service, subscription) do
      {:ok,
       %{
         service: @slug,
         credits_remaining: credits_remaining,
         result: runtime_body
       }}
    end
  end

  def generate(_params, _opts), do: {:error, :invalid_payload}

  defp ensure_service do
    case Payments.get_service_by_slug(@slug) do
      nil -> PublicServices.ensure_cv_generator_registered()
      service -> {:ok, service}
    end
  end

  defp authorize(service, opts) do
    api_key = opts |> Map.get(:api_key) |> blank_to_nil()
    wallet = opts |> Map.get(:wallet) |> blank_to_nil()

    subscription =
      cond do
        api_key -> Payments.get_subscription_by_api_key(api_key)
        wallet -> Payments.get_subscription_by_wallet_and_service(wallet, service.id)
        true -> nil
      end

    cond do
      is_nil(subscription) ->
        {:error, :payment_required}

      subscription.service_id != service.id ->
        {:error, :payment_required}

      subscription.credits_remaining <= 0 ->
        {:error, :insufficient_credits}

      true ->
        {:ok, subscription}
    end
  end

  defp normalize_payload(params) do
    payload =
      params
      |> stringify_keys()
      |> Map.take(@allowed_top_level_fields)

    with profile when is_map(profile) <- Map.get(payload, "profile"),
         {:ok, export_format} <- normalize_export_format(Map.get(payload, "export_format", "pdf")) do
      {:ok,
       payload
       |> Map.put("profile", stringify_keys(profile))
       |> Map.put("export_format", export_format)
       |> Map.put_new("template", "modern")
       |> Map.put_new("locale", "tr-TR")}
    else
      nil -> {:error, :invalid_payload}
      _ -> {:error, :invalid_payload}
    end
  end

  defp normalize_export_format(format) when is_binary(format) do
    normalized = String.downcase(format)

    if normalized in @allowed_export_formats do
      {:ok, normalized}
    else
      {:error, :invalid_payload}
    end
  end

  defp normalize_export_format(_format), do: {:error, :invalid_payload}

  defp runtime_generate_url do
    configured =
      System.get_env("CV_GENERATOR_RUNTIME_URL") ||
        :governance_core
        |> Application.get_env(__MODULE__, [])
        |> Keyword.get(:runtime_generate_url)

    case blank_to_nil(configured) do
      nil -> {:error, :runtime_not_configured}
      url -> {:ok, url}
    end
  end

  defp forward(runtime_url, payload) do
    case Req.post(runtime_url, json: payload, receive_timeout: 30_000) do
      {:ok, %{status: status, body: body}} when status in 200..299 ->
        {:ok, body}

      {:ok, %{status: status}} ->
        {:error, {:runtime_error, status}}

      {:error, _reason} ->
        {:error, :runtime_unavailable}
    end
  end

  defp deduct_and_log(service, subscription) do
    with {:ok, credits_remaining} <- Credits.deduct_credit(subscription.id),
         {:ok, _log} <-
           Payments.log_request(%{
             subscription_id: subscription.id,
             service_id: service.id,
             status: "success"
           }) do
      {:ok, credits_remaining}
    end
  end

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn {key, value} -> {to_string(key), value} end)
  end

  defp blank_to_nil(value) when value in [nil, ""], do: nil

  defp blank_to_nil(value) when is_binary(value) do
    trimmed = String.trim(value)
    if trimmed == "", do: nil, else: trimmed
  end

  defp blank_to_nil(value), do: value
end
