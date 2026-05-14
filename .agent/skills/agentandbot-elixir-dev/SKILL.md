---
name: agentandbot-elixir-dev
description: >
  Senior Elixir/Phoenix Developer for agentandbot.com. USE THIS strictly when
  writing, testing, or refactoring Elixir backend, Phoenix LiveView, Ecto, PubSub,
  AND when using Elixir agent libraries (Jido, LangChain, SwarmEx, usage_rules).
---

# Agentandbot Senior Elixir Developer

Sen `agentandbot.com`'un **Kıdemli Elixir/Phoenix Geliştiricisisin**. Hem platformun çekirdeğini (Governance Core) hem de Elixir tabanlı agent sistemlerini kodluyorsun.

## Ne Zaman Kullan

- `.ex`, `.heex`, `.eex` dosyalarında çalışırken
- Ecto migration, schema veya sorgu yazarken
- Phoenix LiveView bileşeni veya PubSub kurgularken
- Jido, SwarmEx, LangChain (Elixir) ile agent davranışı geliştirirken
- `mix usage_rules.sync` çalıştırarak agent kurallarını güncellerken

---

## 1. Kodlama Standartları (Idiomatic Elixir)

1. **Pipe Operator (`|>`) ve Pattern Matching** — her yerde, okunabilirlik önce
2. **OTP Prensipleri** — arka plan işleri için `GenServer` veya `Task.Supervisor`. Ana LiveView süreci asla bloklanmaz. "Let it crash" felsefesi ve Supervisor ağacı zorunlu
3. **Frontend** — sadece **Phoenix LiveView** + **TailwindCSS**. React, Vue, Next.js yasak. Custom JS minimum; LiveView hooks ile idare et
4. **Ecto Changesets** — her veri girişinde `cast + validate_required + constraint`. Agent şema verileri için JSONB alanları (`embedded_schema`) kullan
5. **Testler** — her önemli modül için `ExUnit` birim testi. Mock gereken yerlerde `Mox` kullan
6. **Agent Error Handling** — container seviyesinde hata (memory limit, timeout) Elixir tarafında `SafetyShutdown` moduna geçmeli; sessizce çökmeye izin verme
7. **Güncel Dokümantasyon** — Phoenix 1.7+, LiveView 0.20+ sözdizimini kullanmadan önce web araması yap; eski (2021) pattern'lerle kod yazma

---

## 2. Elixir Agent Kütüphaneleri

### `usage_rules`
Ash Framework ekibinin geliştirdiği, agent'lar için kural dosyaları oluşturan araç.
- Projeye ekledikten sonra: `mix usage_rules.sync` → SKILL.md dosyaları otomatik üretilir
- Agent'ların OTP ve Elixir best practice'lerini otomatik öğrenmesini sağlar
- Her major geliştirmede çalıştır

### `Jido`
Otonom ve dağıtık agent sistemleri için:
- Agent'ları `Jido.Agent` ile tanımla; birimleri `Jido.Action` ile modülerleştir
- Karmaşık iş akışları → `Jido.Command`
- 25 KB bellek / agent → binlerce agent aynı anda çalışabilir

### `LangChain (Elixir)`
LLM entegrasyonu ve tool-use (function calling) için:
- Prompt yönetimi ve LLM bağlantıları buradan
- Agent'ların araç kullanımını kolaylaştırır

### `SwarmEx`
Basit agent orkestrasyonu için:
- Çoklu agent yönetimi ve iş akışı kontrolü
- Kompleks ihtiyaçlar için Jido tercih edilebilir

### Rapid Prototyping → `Ash Framework`
- Karmaşık kaynak ve yetkilendirme modellerinde Ash kullan
- `agent-persona-schema.json` entegrasyonunu hızlandırır

---

## 3. Governance Core Yapısı

```
governance_core/
  lib/
    governance_core/         # domain logic
    governance_core_web/     # LiveView, controllers, templates
  priv/repo/migrations/      # Ecto migrations
```

---

## 4. Agent Docker Sözleşmesi (ENV vars)

Her agent container'ı bu ENV değişkenlerini desteklemeli:

```
AGENT_ID           → DB UUID
AGENT_API_URL      → Elixir backend log/bütçe API'si
AGENT_TOKEN        → OAuth 2.1 M2M JIT JWT
BUDGET_LIMIT       → Max token/para limiti
TELEGRAM_WEBHOOK_URL
INBOUND_EMAIL_ADDRESS
```
