defmodule GovernanceCore.AgentImages do
  @moduledoc """
  Server-side Gemini image generation for permitted agent profile editors.
  """

  alias GovernanceCore.Marketplace

  @gemini_base_url "https://generativelanguage.googleapis.com/v1beta/models"
  @default_image_model "gemini-3.1-flash-image-preview"
  @image_models ~w(gemini-3.1-flash-image-preview gemini-2.5-flash-image gemini-3-pro-image-preview)
  @one_by_one_png Base.decode64!(
                    "iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII="
                  )

  def generate_agent_image(agent_id, attrs) do
    attrs = stringify_keys(attrs || %{})
    actor = Map.get(attrs, "actor") || Map.get(attrs, "user") || Map.get(attrs, "user_id")

    with :ok <- authorize(actor),
         {:ok, image_kind} <- image_kind(Map.get(attrs, "image_kind", "headshot")),
         prompt when prompt not in [nil, ""] <- Map.get(attrs, "prompt"),
         {:ok, %{bytes: bytes, mime_type: mime_type}} <- generate_with_gemini(prompt, attrs),
         {:ok, public_url} <- persist_image(agent_id, image_kind, bytes, mime_type),
         {:ok, _agent} <-
           Marketplace.update_agent_profile_image(agent_id, image_kind, public_url, %{
             "provider" => "gemini",
             "model" => model(attrs),
             "prompt" => prompt,
             "actor" => actor
           }) do
      {:ok,
       %{
         agent_id: agent_id,
         image_kind: image_kind,
         image_url: public_url,
         provider: "gemini",
         model: model(attrs)
       }}
    else
      nil -> {:error, :missing_prompt}
      {:error, reason} -> {:error, reason}
    end
  end

  def permitted?(actor), do: authorize(actor) == :ok

  def allowed_users do
    env =
      System.get_env("AGENT_IMAGE_ALLOWED_USERS") ||
        System.get_env("AGENT_IMAGE_ADMINS") ||
        "admin@agentandbot.com,admin@harezm.com"

    env
    |> String.split([",", ";", "\n"], trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp authorize(actor) when actor in [nil, ""], do: {:error, :unauthorized}

  defp authorize(actor) do
    normalized = actor |> to_string() |> String.downcase()

    if normalized in Enum.map(allowed_users(), &String.downcase/1) do
      :ok
    else
      {:error, :unauthorized}
    end
  end

  defp image_kind("full_body"), do: {:ok, "full_body"}
  defp image_kind("headshot"), do: {:ok, "headshot"}
  defp image_kind(_), do: {:error, :invalid_image_kind}

  defp generate_with_gemini(prompt, attrs) do
    key = provider_key(attrs)

    cond do
      key in [nil, ""] ->
        {:error, :missing_gemini_api_key}

      key == "test" ->
        {:ok, %{bytes: @one_by_one_png, mime_type: "image/png"}}

      true ->
        call_gemini(key, prompt, attrs)
    end
  end

  defp provider_key(attrs) do
    [
      Map.get(attrs, "provider_api_key"),
      Map.get(attrs, "gemini_api_key"),
      System.get_env("GEMINI_API_KEY")
    ]
    |> Enum.find_value(fn
      value when value in [nil, ""] -> nil
      value -> value
    end)
  end

  defp call_gemini(key, prompt, attrs) do
    body = %{
      contents: [
        %{
          parts: [
            %{
              text:
                [
                  "Create a realistic but clearly fictional AI worker persona image.",
                  "Do not depict a real identifiable person.",
                  "Use professional marketplace profile lighting.",
                  prompt
                ]
                |> Enum.join(" ")
            }
          ]
        }
      ],
      generationConfig: %{
        responseModalities: ["TEXT", "IMAGE"],
        imageConfig: %{
          aspectRatio: Map.get(attrs, "aspect_ratio", "1:1")
        }
      }
    }

    endpoint = "#{@gemini_base_url}/#{model(attrs)}:generateContent"

    case Req.post(endpoint,
           headers: [{"x-goog-api-key", key}, {"content-type", "application/json"}],
           json: body,
           receive_timeout: 120_000
         ) do
      {:ok, %{status: status, body: response}} when status in 200..299 ->
        parse_gemini_image(response)

      {:ok, %{status: 429, body: body}} ->
        {:error, {:gemini_quota_exceeded, body}}

      {:ok, %{status: status, body: body}} ->
        {:error, {:gemini_error, status, body}}

      {:error, reason} ->
        {:error, {:gemini_request_failed, reason}}
    end
  end

  defp parse_gemini_image(%{"candidates" => candidates}) do
    candidates
    |> Enum.flat_map(&(get_in(&1, ["content", "parts"]) || []))
    |> Enum.find_value(fn
      %{"inlineData" => %{"data" => data, "mimeType" => mime_type}} ->
        {:ok, %{bytes: Base.decode64!(data), mime_type: mime_type}}

      %{"inline_data" => %{"data" => data, "mime_type" => mime_type}} ->
        {:ok, %{bytes: Base.decode64!(data), mime_type: mime_type}}

      _ ->
        nil
    end) || {:error, :no_image_returned}
  end

  defp parse_gemini_image(_response), do: {:error, :invalid_gemini_response}

  defp persist_image(agent_id, image_kind, bytes, mime_type) do
    ext = extension(mime_type)
    timestamp = System.system_time(:millisecond)
    relative_dir = Path.join(["images", "generated", "agents", agent_id])

    static_root =
      System.get_env("AGENT_IMAGE_OUTPUT_DIR") ||
        Path.join(:code.priv_dir(:governance_core), "static")

    absolute_dir = Path.join(static_root, relative_dir)
    filename = "#{image_kind}-#{timestamp}.#{ext}"
    absolute_path = Path.join(absolute_dir, filename)

    with :ok <- File.mkdir_p(absolute_dir),
         :ok <- File.write(absolute_path, bytes) do
      {:ok, "/" <> Path.join(relative_dir, filename)}
    end
  end

  defp extension("image/jpeg"), do: "jpg"
  defp extension("image/webp"), do: "webp"
  defp extension(_mime_type), do: "png"

  defp model(attrs) do
    requested = Map.get(attrs, "image_model") || System.get_env("GEMINI_IMAGE_MODEL")

    if requested in @image_models do
      requested
    else
      @default_image_model
    end
  end

  defp stringify_keys(map) when is_map(map) do
    Map.new(map, fn {key, value} -> {to_string(key), value} end)
  end
end
