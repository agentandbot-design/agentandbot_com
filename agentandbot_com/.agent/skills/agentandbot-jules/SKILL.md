---
name: agentandbot-jules
description: >
  Jules (Google AI Coding Agent) integration for agentandbot.com. USE THIS when
  delegating GitHub tasks to Jules — issue triage, PR reviews, bug fixes, CI
  failures, or scheduled code maintenance. Jules watches the GitHub repo and acts
  autonomously via GitHub issue labels and Scheduled Tasks.
---

# Agentandbot — Jules Integration

Jules, GitHub üzerinde çalışan Google'ın AI coding agentıdır.
**REST API'si yoktur.** İki mekanizma ile çalışır:
1. GitHub issue'ya `jules` label'ı ekle → Jules otomatik başlar
2. Jules UI'ından Scheduled Task oluştur → periyodik çalışır

## Nasıl Çalışır (Gerçek Akış)

```
GitHub Issue  → label: "jules" ekle → Jules kodu yazar → Branch + PR açar → Sen merge edersin
Jules UI      → Scheduled Task oluştur → günlük/haftalık otomatik çalışır
```

## Ne Zaman Jules'a İş Verilir

| Senaryo | Yöntem |
|---------|--------|
| Bug fix | Issue aç → `jules` label ekle |
| Yeni özellik implement | Issue aç + detaylı açıkla → `jules` label |
| Devamlı kod review | Jules UI → Scheduled Task (Daily) |
| Test yazımı | Issue aç → `jules` label + "write ExUnit tests for X" |
| CI hata düzeltme | Issue aç → CI logunu yapıştır → `jules` label |
| Refactor | Issue aç → `jules` label |

## Antigravity'nin Jules ile İş Bölümü

```
Antigravity  → Yeni özellik tasarımı, mimari kararlar, skill yazımı
Jules        → GitHub issue → PR, bug fix, test yazımı, scheduled review
```

---

## 1. Jules Kurulumu (Bir Kere)

1. `https://jules.google.com` → Google hesabıyla giriş
2. **Connect GitHub** → `agentandbot-design/agentandbot_com` reposunu seç
3. **Configuration** → Setup Script ekle (Elixir ortamı için):
   ```bash
   # Jules VM'de Elixir kurulumu
   curl -fsSO https://elixir-lang.org/install.sh
   sh install.sh elixir@1.19 otp@27
   export PATH="$HOME/.elixir-install/installs/otp/27/bin:$HOME/.elixir-install/installs/elixir/1.19/bin:$PATH"
   cd governance_core
   mix deps.get
   mix compile
   ```
4. **Run and Snapshot** tıkla → environmet snapshot oluşturulur

---

## 2. GitHub Issue ile Jules'u Tetikleme

### Antigravity → GitHub Issues API ile issue aç

```elixir
# lib/governance_core/jules_client.ex
defmodule GovernanceCore.JulesClient do
  @moduledoc """
  Antigravity ve platform agentları buradan Jules'a iş verir.
  Jules'ın REST API'si yoktur — GitHub Issues üzerinden tetiklenir.
  """

  @repo "agentandbot-design/agentandbot_com"
  @api_url "https://api.github.com"

  @project_context """
  PROJE: Elixir 1.19 / Phoenix 1.7+ / LiveView / Tailwind / Ecto / PostgreSQL
  DESIGN: bg #0B0F14, card #121826, accent #3B82F6, font Inter — kesinlikle değiştirme
  TEST: ExUnit + Mox
  OTP: Ana process blocklama, GenServer.call zinciri yasak
  """

  @doc """
  Antigravity'den Jules'a görev ver.
  GitHub'da issue açar ve 'jules' label'ı ekler → Jules otomatik başlar.
  """
  def assign_task(title, body, opts \\ []) do
    labels = Keyword.get(opts, :labels, ["jules"])
    triggered_by = Keyword.get(opts, :triggered_by, "Antigravity")

    issue_body = """
    **Triggered by:** #{triggered_by}

    #{@project_context}

    ---

    #{body}
    """

    with {:ok, issue} <- create_issue(title, issue_body, labels) do
      {:ok, issue}
    end
  end

  @doc """
  Test yazımı görevi — DesignAgent bir sayfa bitirince çağırır.
  """
  def request_tests_for(module_name) do
    assign_task(
      "Write ExUnit tests for #{module_name}",
      """
      `#{module_name}` için ExUnit testleri yaz:
      - Happy path
      - Edge case: boş input, geçersiz format
      - LiveView ise: mount/handle_event testleri
      - Dış bağımlılık varsa Mox kullan
      """,
      triggered_by: "DesignAgent"
    )
  end

  @doc """
  Bug raporu — herhangi bir platform agent'ı çağırabilir.
  """
  def report_bug(description, context \\ "") do
    assign_task(
      "Bug: #{String.slice(description, 0, 60)}",
      description <> "\n\n**Context:**\n" <> context,
      labels: ["jules", "bug"],
      triggered_by: "AutoDetect"
    )
  end

  # ─── GitHub Issues API ────────────────────────────────────────────────

  defp create_issue(title, body, labels) do
    token = System.get_env("GITHUB_TOKEN") ||
      raise "GITHUB_TOKEN env değişkeni eksik!"

    Req.post(
      "#{@api_url}/repos/#{@repo}/issues",
      headers: [
        {"Authorization", "Bearer #{token}"},
        {"Accept", "application/vnd.github+json"}
      ],
      json: %{title: title, body: body, labels: labels}
    )
    |> case do
      {:ok, %{status: 201, body: body}} -> {:ok, body}
      {:ok, %{status: s, body: b}} -> {:error, {s, b}}
      {:error, r} -> {:error, r}
    end
  end
end
```

---

## 3. Scheduled Tasks (Devamlı Görevler)

Jules UI'ından kurulur — **kod değil, UI konfigürasyonu**:

### Kurulum Adımları
1. `jules.google.com` → Task input alanı
2. Alt sağdaki **Planning dropdown** → **Scheduled Task** seç
3. **Daily** veya **Weekly** seç
4. Prompt yaz (aşağıdaki şablonlar)
5. **Submit**

### Önerilen Scheduled Task Promptları

**Günlük Kod Review (Daily):**
```
Elixir/Phoenix projesini review et:
1. Ecto changeset validasyonu eksik mi?
2. LiveView güvensiz assign var mı?
3. Design System ihlali: bg değeri #0B0F14 olmalı, accent #3B82F6
4. OTP bloklama (GenServer.call zinciri) var mı?
5. Yeni modüllerin ExUnit testi yazılmış mı?
Sorun varsa GitHub issue aç, label: "jules-found"
```

**Haftalık Güvenlik Taraması (Weekly):**
```
Güvenlik review:
1. Commit edilmiş .env veya secret var mı?
2. SQL injection riski (raw query) var mı?
3. Bağımlılık güvenlik açığı: mix audit çalıştır
4. Açık port/endpoint erişim kontrolsüz var mı?
Sorun varsa GitHub issue aç, label: "security"
```

---

## 4. GitHub Label ile Otomatik Tetikleme

GitHub Actions ile `jules` label'ı eklenince Jules'a yorum yap:

```yaml
# .github/workflows/jules-issue-triage.yml
on:
  issues:
    types: [labeled]

jobs:
  comment-on-jules-label:
    if: github.event.label.name == 'jules'
    runs-on: ubuntu-latest
    steps:
      - uses: actions/github-script@v7
        with:
          script: |
            github.rest.issues.createComment({
              owner: context.repo.owner,
              repo: context.repo.repo,
              issue_number: context.issue.number,
              body: '🤖 Jules bu issue\'yu incelemeye aldı. Yakında PR açacak.\n\n_Agent-triggered · agentandbot platform_'
            })
```

---

## 5. AGENTS.md (Jules'a Proje Bağlamı)

Jules, repo root'ta `AGENTS.md` dosyasını otomatik okur.
Bizim `AGENTS.md` zaten var — güncel tut.

```markdown
# AGENTS.md için önemli bilgiler
- Stack: Elixir/Phoenix LiveView (React/Vue kullanma)
- Design System: bg #0B0F14, accent #3B82F6 — değiştirme
- Test: mix test çalıştır, ExUnit + Mox kullan
- Wire protocol: ABL.ONE/1.0 binary, 8 byte frame
```

---

## Kısıtlamalar

```
✅ Bug fix, refactor, test yazımı → Jules (GitHub issue + label)
✅ Scheduled review/güvenlik tarama → Jules (Scheduled Task, UI'dan)
✅ Issue triage → Jules (label ile otomatik)
🚫 REST API çağrısı YOKTUR — eski JulesClient.ex'teki curl'ler çalışmaz
🚫 Yeni mimari → Antigravity
🚫 Stitch design → Design Agent
🚫 ABL.ONE protokol → Swarm Expert
```
