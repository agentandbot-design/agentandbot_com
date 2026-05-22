defmodule GovernanceCoreWeb.PublicServiceControllerTest do
  use GovernanceCoreWeb.ConnCase, async: false

  alias GovernanceCore.Payment.{Credits, Payments}
  alias GovernanceCore.PublicServices
  alias GovernanceCore.Repo

  setup do
    System.delete_env("CV_GENERATOR_RUNTIME_URL")
    previous = Application.get_env(:governance_core, PublicServices.CvGeneratorGateway)
    Application.delete_env(:governance_core, PublicServices.CvGeneratorGateway)

    on_exit(fn ->
      System.delete_env("CV_GENERATOR_RUNTIME_URL")

      if previous do
        Application.put_env(:governance_core, PublicServices.CvGeneratorGateway, previous)
      else
        Application.delete_env(:governance_core, PublicServices.CvGeneratorGateway)
      end
    end)
  end

  test "cv generator service metadata is public and discoverable", %{conn: conn} do
    payload =
      conn
      |> get(~p"/api/public-services/cv-generator")
      |> json_response(200)

    assert payload["data"]["slug"] == "cv-generator"
    assert payload["data"]["api_endpoint"] == "https://cv.e-any.online/api/generate"
    assert payload["data"]["gateway_endpoint"] == "/api/public-services/cv-generator/generate"
    assert "signed_embed" in payload["data"]["auth_modes"]
    refute inspect(payload) =~ "vault://"
  end

  test "skills and openapi include cv generator discovery", %{conn: conn} do
    skills = conn |> get(~p"/skills.json") |> json_response(200)
    names = Enum.map(skills["skills"], & &1["name"])

    assert "get_cv_generator_service" in names

    openapi = conn |> get(~p"/api/openapi.json") |> json_response(200)
    assert Map.has_key?(openapi["paths"], "/api/public-services/cv-generator")
    assert Map.has_key?(openapi["paths"], "/api/public-services/cv-generator/generate")
    assert Map.has_key?(openapi["components"]["schemas"], "PublicServiceCard")
    assert Map.has_key?(openapi["components"]["schemas"], "CvGeneratorRequest")
  end

  test "generate endpoint requires payment credentials", %{conn: conn} do
    payload =
      conn
      |> post(~p"/api/public-services/cv-generator/generate", valid_cv_payload())
      |> json_response(402)

    assert payload["error"] == "payment_required"
    refute inspect(payload) =~ "vault://"
  end

  test "generate endpoint rejects subscriptions without credits", %{conn: conn} do
    {:ok, service} = PublicServices.ensure_cv_generator_registered()
    {:ok, subscription} = Payments.find_or_create_subscription(service.id, "0xBUYER")

    payload =
      conn
      |> put_req_header("x-api-key", to_string(subscription.api_key))
      |> post(~p"/api/public-services/cv-generator/generate", valid_cv_payload())
      |> json_response(402)

    assert payload["error"] == "payment_required"
  end

  test "generate endpoint validates paid access but does not charge when runtime is not configured",
       %{
         conn: conn
       } do
    {:ok, service} = PublicServices.ensure_cv_generator_registered()
    {:ok, subscription} = Payments.find_or_create_subscription(service.id, "0xFUNDED")
    {:ok, 1} = Credits.add_credits(subscription.id, 1)

    payload =
      conn
      |> put_req_header("x-api-key", to_string(subscription.api_key))
      |> post(~p"/api/public-services/cv-generator/generate", valid_cv_payload())
      |> json_response(503)

    assert payload["error"] == "runtime_not_configured"
    assert Repo.reload!(subscription).credits_remaining == 1
    refute inspect(payload) =~ "vault://"
  end

  defp valid_cv_payload do
    %{
      "profile" => %{
        "name" => "Ada Lovelace",
        "headline" => "AI worker orchestration specialist",
        "experience" => ["Agent workflow design", "Automation governance"]
      },
      "template" => "modern",
      "locale" => "tr-TR",
      "export_format" => "pdf",
      "source_site" => "agentandbot.com"
    }
  end
end
