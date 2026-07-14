# AgentAndBot Workspace

AgentAndBot, Harezm Ekosistemi icindeki Swarm OS ve AI worker marketplace merkezidir. Bu klasorun ana uygulamasi `governance_core/` altindaki Phoenix LiveView projesidir.

## Aktif Uygulama

- `governance_core/`: agentandbot.com platformunun Phoenix backend ve LiveView arayuzu.
- `services/cv_generator/`: `cv.e-any.online` icin Docker-ready CV Generator runtime servisi.
- `KADRO/`: KADRO platformuna ait ayri/yardimci calisma alani.
- `blueprint/`, `specs/`, `tasks/`: eski veya destekleyici planlama kaynaklari. Guncel ana hafiza icin kok `README.md` ve `governance_core/HANDOFF.md` okunmalidir.

## Governance Core Durumu

Son stabilizasyon hedefi:

- KADRO agent ise alma, gorev yurutme simülasyonu, XP/level/achievement modeli.
- Agent DNA portability: JSON export/import ve Brain Sync arayuzu.
- 1-click sandbox deploy simülasyonu ve Hostinger VPS yonlendirmesi.
- Ortak Swarm OS navigasyon kabugu.
- Tool Directory, Feed, Payment Dashboard ve Scenario Board girisleri.

Dogru calisma dizini:

```powershell
cd B:\DEV\HAREZM_EKOSISTEMI\LesTupid\les_ai\agentandbot\governance_core
```

Temel dogrulama:

```powershell
mix test
$env:TEMP='C:\tmp'; $env:TMP='C:\tmp'; mix ecto.migrate
```

Yerel sunucu:

```powershell
$env:TEMP='C:\tmp'; $env:TMP='C:\tmp'; $env:PORT='4001'; mix phx.server
```

Ana ekranlar:

- `http://127.0.0.1:4001/scenarios`
- `http://127.0.0.1:4001/agents`
- `http://127.0.0.1:4001/tools`
- `http://127.0.0.1:4001/feed`
- `http://127.0.0.1:4001/payment/dashboard`

## Desteklenen Standartlar ve Protokoller

AgentAndBot, otonom agent'lar arasındaki uyumluluğu artırmak için 10 modern protokol ve standardı destekler:
- Detaylar ve mimari spesifikasyonlar için [specs/protocols/README.md](file:///b:/DEV/HAREZM_EKOSISTEMI/LesTupid/les_ai/agentandbot/specs/protocols/README.md) dosyasını inceleyin.
- Ajanların otonom rehberi için `agentandbot-protocols` yeteneği (`governance_core/.agent/skills/agentandbot-protocols/SKILL.md`) mevcuttur.

## Agentlar Icin Not

Yeni ise baslamadan once mutlaka `governance_core/HANDOFF.md` oku. Orada son yapilanlar, aktif riskler, siradaki is sirasi ve dokunulmamasi gereken alanlar yaziyor.
