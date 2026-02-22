defmodule GovernanceCore.JulesClient do
  @moduledoc """
  Jules AI Coding Agent — Resmi API istemcisi.

  Jules REST API (alpha): https://jules.googleapis.com/v1alpha
  Auth: X-Goog-Api-Key header

  Platform agentları bu modülü kullanarak Jules'a
  programmatik olarak görev verebilir.

  ## Temel Akış

      # 1. Session oluştur (Jules görevi başlar, AUTO_CREATE_PR ile PR açar)
      {:ok, session} = JulesClient.create_session("Fix the login bug", branch: "main")

      # 2. Session ID ile durumu takip et
      {:ok, status} = JulesClient.get_session(session["id"])

      # 3. PR oluşturulduysa URL'yi al
      pr_url = get_in(status, ["outputs", Access.at(0), "pullRequest", "url"])
  """

  require Logger

  @base_url "https://jules.googleapis.com/v1alpha"

  # Proje kaynak adı — Jules'a bağlı repo
  # `GET /sources` ile doğrulanacak format
  @source "sources/github/agentandbot-design/agentandbot_com"

  @project_context """
  PROJE: Elixir 1.19 / Phoenix 1.7+ / LiveView / Tailwind / Ecto / PostgreSQL
  DESIGN: bg #0B0F14, card #121826, accent #3B82F6, font Inter
  TEST: ExUnit + Mox
  OTP: GenServer bloklama yasak, Task.Supervisor kullan
  PROTOCOL: ABL.ONE/1.0 binary, 8-byte frame, Gibberlink token
  """

  # ─── Public API ────────────────────────────────────────────────────────────

  @doc """
  Bağlı GitHub repolarını listele.
  İlk kurulumda source adını doğrulamak için çağır.
  """
  def list_sources do
    get("/sources")
  end

  @doc """
  Yeni bir Jules görevi başlat. Jules otomatik plan oluşturur ve PR açar.

  ## Seçenekler
  - `:branch` — başlangıç branch'i (default: "main")
  - `:auto_pr` — true ise otomatik PR aç (default: true)
  - `:title` — session başlığı
  - `:triggered_by` — loglama için

  ## Örnek
      JulesClient.create_session(
        "Add ExUnit tests for MarketplaceLive",
        branch: "main",
        title: "MarketplaceLive tests",
        triggered_by: "DesignAgent"
      )
  """
  def create_session(prompt, opts \\ []) do
    branch = Keyword.get(opts, :branch, "main")
    auto_pr = Keyword.get(opts, :auto_pr, true)
    title = Keyword.get(opts, :title, String.slice(prompt, 0, 60))
    triggered_by = Keyword.get(opts, :triggered_by, "GovernanceCore")

    Logger.info("[JulesClient] Session oluşturuluyor. triggered_by=#{triggered_by}")

    body = %{
      title: title,
      prompt: @project_context <> "\n\nGÖREV:\n" <> prompt,
      sourceContext: %{
        source: @source,
        githubRepoContext: %{startingBranch: branch}
      },
      automationMode: if(auto_pr, do: "AUTO_CREATE_PR", else: "MANUAL")
    }

    post("/sessions", body)
  end

  @doc """
  Var olan bir session'ın durumunu getir.
  PR URL'si `outputs[0].pullRequest.url` altındadır.
  """
  def get_session(session_id) do
    get("/sessions/#{session_id}")
  end

  @doc """
  Tüm session'ları listele (son 10).
  """
  def list_sessions(page_size \\ 10) do
    get("/sessions?pageSize=#{page_size}")
  end

  @doc """
  Manuel plan onayı gerektiren session'ları onayla.
  """
  def approve_plan(session_id) do
    post("/sessions/#{session_id}:approvePlan", %{})
  end

  # ─── Convenience Wrappers ──────────────────────────────────────────────────

  @doc "Test yazımı görevi — DesignAgent bir LiveView bitirince çağırır."
  def request_tests_for(module_name, opts \\ []) do
    create_session(
      "`#{module_name}` için ExUnit testleri yaz:\n" <>
        "- Happy path\n- Edge case: boş input, geçersiz format\n" <>
        "- LiveView ise: mount/handle_event testleri\n- Dış bağımlılık varsa Mox kullan",
      Keyword.merge([title: "Tests: #{module_name}", triggered_by: "DesignAgent"], opts)
    )
  end

  @doc "Nightly review — GovernanceCore.Scheduler tarafından gece çağrılır."
  def nightly_review do
    create_session(
      """
      Günlük kod review:
      1. Ecto changeset validasyonu eksik modül var mı?
      2. LiveView güvensiz assign var mı?
      3. Design System v1 ihlali (renk, font)?
      4. OTP bloklama (GenServer.call zinciri) var mı?
      5. Yeni modüllerin ExUnit testi yazılmış mı?
      Sorun varsa GitHub issue aç, label: jules-found. Küçük fix ise direkt PR aç.
      """,
      title: "Nightly Code Review",
      triggered_by: "NightlyScheduler",
      # review sonuçlarını issue olarak raporla
      auto_pr: false
    )
  end

  @doc "Güvenlik taraması — haftalık çağrılır."
  def weekly_security_scan do
    create_session(
      """
      Haftalık güvenlik taraması:
      1. Commit edilmiş .env veya secret var mı?
      2. mix audit çalıştır — güvenlik açığı olan bağımlılık var mı?
      3. Açık endpoint erişim kontrolsüz var mı?
      4. SQL injection riski (raw query) var mı?
      Sorun varsa GitHub issue aç, label: security
      """,
      title: "Weekly Security Scan",
      triggered_by: "SecurityScheduler",
      auto_pr: false
    )
  end

  # ─── HTTP Helpers ──────────────────────────────────────────────────────────

  defp api_key do
    System.get_env("JULES_API_KEY") ||
      raise "JULES_API_KEY env değişkeni eksik! .env dosyasını kontrol et."
  end

  defp headers do
    [{"X-Goog-Api-Key", api_key()}, {"Content-Type", "application/json"}]
  end

  defp get(path) do
    Req.get(@base_url <> path, headers: headers())
    |> handle_response()
  end

  defp post(path, body) do
    Req.post(@base_url <> path, headers: headers(), json: body)
    |> handle_response()
  end

  defp handle_response({:ok, %{status: s, body: body}}) when s in 200..299 do
    Logger.info("[JulesClient] OK #{s}")
    {:ok, body}
  end

  defp handle_response({:ok, %{status: s, body: body}}) do
    Logger.error("[JulesClient] Hata #{s}: #{inspect(body)}")
    {:error, {s, body}}
  end

  defp handle_response({:error, reason}) do
    Logger.error("[JulesClient] HTTP hata: #{inspect(reason)}")
    {:error, reason}
  end
end
