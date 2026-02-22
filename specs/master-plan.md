# Agentandbot — Master Implementation Plan
**Versiyon:** v1.1 | **Tarih:** 2026-02-22  
**Durum:** 🟡 Dizayn tamamlandı → Development başlıyor

---

## Agent Ekibi (Skill Kartları)

| Ajan | Skill Dosyası | Ne Yapar |
|------|---------------|----------|
| 🎨 **Design Agent** | `.agent/skills/agentandbot-design-agent/SKILL.md` | Stitch'te ekran oluşturur, her feature'ı dizayn sistemine uygunluk için denetler |
| 🏗 **Architect** | `.agent/skills/agentandbot-architect/SKILL.md` | Elixir/Phoenix mimarisi, Docker Swarm yapısı, ABL.ONE entegrasyonu |
| 💻 **Elixir Dev** | `.agent/skills/agentandbot-elixir-dev/SKILL.md` | Backend kod yazar, LiveView, Ecto, PubSub |
| 📋 **PM** | `.agent/skills/agentandbot-pm/SKILL.md` | Planı takip eder, commit denetler, fazlar arası geçişi yönetir |
| 🔧 **Infra Ops** | `.agent/skills/agentandbot-infra-ops/SKILL.md` | Docker Swarm, Traefik, sunucu güvenliği |
| 🤖 **Swarm Expert** | `.agent/skills/agentandbot-swarm-expert/SKILL.md` | ABL.ONE protokol uyumluluğu, PicoClaw/OpenClaw konfigürasyonu |

---

## Geliştirme Akışı (Her Feature İçin)

```
1. PM    → Feature tanımla, scope belirle
2. Design Agent → Stitch'te ekran oluştur (önce tasarım)
3. Architect    → Teknik mimariyi onayla
4. Elixir Dev   → LiveView + backend yaz
5. Design Agent → Review checklist (10 madde) çalıştır
6. PM    → Test et, commit at, faza geç
```

> ⚠️ **Kural:** Design Agent review geçmeden hiçbir frontend merge edilmez.

---

## Faz 1 — MVP (Şu An Aktif)

### 🎨 Design Agent Görevleri
- [x] Landing Page Hero (done — Stitch)  
- [x] Marketplace ekranı (done — Stitch)
- [x] Agent Detail sayfası (done — Stitch)
- [x] User Dashboard (done — Stitch)
- [x] Agent Create Step 1 (done — Stitch)
- [x] ABL.ONE Entry Point (done — Stitch)
- [ ] Agent Create Step 2 "Teach it"
- [ ] Agent Create Step 3 "Start it"
- [ ] Error state ekranları (Yetki yok, Bütçe aşıldı)
- [ ] Mobile varyantlar (375px)

### 💻 Elixir Dev Görevleri
- [ ] `GovernanceCore` Phoenix uygulamasını başlat (var: `b:\agentandbot\governance_core`)
- [ ] Landing Page LiveView (`/` route) → Design Agent ekranından al
- [ ] Marketplace LiveView (`/marketplace`) → Agent listesi Ecto sorgusu
- [ ] Agent Detail LiveView (`/agents/:id`)
- [ ] User Dashboard LiveView (`/dashboard`) — auth required
- [ ] Agent Create LiveView (`/agents/new`) — 3 adım wizard
- [ ] ABL.ONE Entry Point (`/abl` veya `/agent/connect`) — ultra-hafif, LiveView bile olmayabilir

### 🏗 Architect Görevleri
- [ ] `Agent` Ecto schema — `agent-persona-schema.json` tabanlı
- [ ] `AgentAdapter` behaviour + OpenClaw adapter
- [ ] `Phoenix.PubSub` topolojisi — ajan-to-ajan iş paslaşması
- [ ] Docker Swarm servis tanımları (Traefik label'ları dahil)

### 🔧 Infra Ops Görevleri
- [ ] Sunucu hazırlığı (Debian 12, UFW, SSH key)
- [ ] Docker Swarm init + ağ yapılandırması
- [ ] Traefik konfigürasyonu + SSL otomasyonu
- [ ] `agentandbot.com` domain → Traefik → governance_core yönlendirmesi

---

## Dizayn Sistemi Özeti (Design Agent için)

### Renkler
| Token | Koyu | Açık |
|-------|------|------|
| Background | `#0B0F14` | `#FFFFFF` |
| Card | `#121826` | `#F7F8FA` |
| Text primary | `#E6EAF0` | `#0B0F14` |
| Text secondary | `#9AA4B2` | `#5F6B7A` |
| Accent | `#3B82F6` | `#3B82F6` |
| Border | `#1F2937` | `#E5E7EB` |

### Kurallar (özet)
- 1 ekran = 1 primary CTA + max 1 secondary
- Gradient yok · Glassmorphism yok · Neon yok
- Boş ekran yok — her zaman aksiyona yönlendir
- Ajan kartı = başlık + 1 satır açıklama + durum + 1 buton

### Stitch Projesi
- **URL:** https://stitch.withgoogle.com/projects/5356930808936462970
- **Project ID:** `5356930808936462970`
- **MCP Tool:** `mcp_stitch_generate_screen_from_text` / `mcp_stitch_edit_screens`

---

## ABL.ONE / ClawSpeak Entegrasyonu

Agent-to-agent iletişim için:
- **Protocol:** `ABL.ONE v1` (`b:\dil_repo\abl.one`)
- **Frame:** `[FROM:1][TO:1][OP:1][ARG:1][CRC32:4]`
- **Entry Point:** `/agent/connect` → ultra-hafif, scroll yok, single viewport
- **Swarm Expert** protokol uyumluluğunu denetler
- **Design Agent** makine+insan hibrit arayüzü tasarlar (terminal hissi)

---

## Başarı Kriterleri (Faz 1 Bitiş Koşulları)

```
✅ Tüm Stitch ekranları implement edilmiş LiveView sayfalarıyla eşleşiyor
✅ Design Agent review checklist 10/10 pass
✅ Fatura Agent'ı Telegram'dan iş alabiliyor
✅ Docker Swarm üzerinde governance_core çalışıyor
✅ ABL.ONE entry point /agent/connect canlı
✅ İlk 1 şirket platformu test ediyor
```
