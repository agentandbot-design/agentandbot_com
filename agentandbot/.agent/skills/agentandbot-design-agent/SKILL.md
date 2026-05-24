---
name: agentandbot-design-agent
description: >
  Agentandbot Design Agent (Synchronized Creative Architect). USE THIS whenever a new
  feature is being built or reviewed. Checks design compliance, creates Stitch screens,
  edits existing screens, and runs the Synchronizer Protocol before any merge.
  It is the single source of truth for all visual decisions on agentandbot.com.
---

# Agentandbot Design Agent — Synchronized Creative Architect (SCA)

Sen Antigravity olarak bu skill'i aktif ettiğinde **Synchronized Creative Architect (SCA)** rolüne giriyorsun. Üç katmanı sürekli senkronize tutmak senin görevin:
- **Backend (Elixir/Phoenix)** — Ecto şemaları, LiveView assign'ları, PubSub olayları
- **Tasarım (Design System v1)** — Stitch MCP'deki referans ekranlar
- **Protokol (ABL.ONE)** — Makine arayüzlerinin görsel temsili

---

## NE ZAMAN AKTİF ET (Antigravity için tetikleyiciler)

Bu skill'i şu durumlarda MUTLAKA oku:

- Yeni bir Phoenix LiveView sayfası veya bileşeni yapılıyorsa → önce Stitch ekranı oluştur
- Elixir `Agent` şemasına yeni alan eklendiyse → etkilenen Stitch ekranlarını güncelle
- Kullanıcı "frontend yap", "ekran oluştur", "tasarım", "Stitch" diyorsa → bu skill
- Bir özellik bittiğinde review istenirse → Review Checklist'i çalıştır
- Backend veri tipi değişirse → SYNC ALERT bas ve görsel etkisini kontrol et

---

## SYNCHRONIZER PROTOCOL

Her merge öncesi bu 4 adımı çalıştır:

### Adım 1 — Backend Check
> Elixir şeması veya fonksiyon değişti mi? LiveView assign'ları etkilendi mi?
- Status türleri değiştiyse → her badge hâlâ doğru renk token'ına mı bakıyor?
- Yeni alan eklendiyse → Stitch ekranında bu alan mevcut mu?
- Alan silindiyse → herhangi bir `.heex` template'inde hâlâ referans var mı?


> Yoksa → `mcp_stitch_generate_screen_from_text` çalıştır, sonra devam et.

---

## DESIGN SYSTEM v1 — TOKEN'LAR

```
# Zeminler
BG_DARK     = #0B0F14    BG_LIGHT  = #FFFFFF
CARD_DARK   = #121826    CARD_LIGHT = #F7F8FA

# Metinler
TEXT_PRI_DARK  = #E6EAF0    TEXT_SEC_DARK  = #9AA4B2
TEXT_PRI_LIGHT = #0B0F14    TEXT_SEC_LIGHT = #5F6B7A

# Aksiyon — ekran başına TEK vurgu rengi
ACTION      = #3B82F6    HOVER  = #2563EB    SOFT = #93C5FD

# Durum
OK    = #22C55E    WARN  = #F59E0B
ERR   = #EF4444    IDLE  = #64748B

# Sınırlar
BORDER_DARK  = #1F2937    BORDER_LIGHT = #E5E7EB

# Tipografi
FONT_UI   = Inter        (tüm arayüz metni)
FONT_MONO = monospace    (loglar, ABL.ONE çıktısı, kod)
RADIUS    = 8px          (kart, buton, input)
RADIUS_SM = 4px          (badge, tag)
```

---

## TASARIM KURALLARI (asla aşılmaz)

```
01  Ekran başına 1 primary CTA, en fazla 1 secondary CTA
02  Gradient yok · Glassmorphism yok · Glow yok · Neon yok
03  Anlamsız ikon yok — eğer yardımcı değilse çıkar
04  Boş ekran yok — her empty state bir aksiyona yönlendirir
05  Teknik jargon yok — fiil önce: Başlat · Durdur · Gönder · Tekrar Dene
06  Agent kartı = başlık | 1 satır açıklama | durum badge | 1 buton
07  Durum her zaman görünür; loglar her zaman 1 adımda erişilebilir
08  Her iki temada WCAG AA kontrast
09  Mobil önce — 375px genişlikte yatay kaydırma yok
10  Backend status değerleri yukarıdaki STATUS_ token'larına eşlenmiş olmalı
```

---

## BİLEŞEN YAPILARI

### Agent Card
```
╔═══════════════════════════════════╗
║ ResearchAgent Pro    ● Çalışıyor  ║  ← başlık + status badge
║ Rakip analizi yapıp rapor verir.  ║  ← 1 satır, max 10 kelime
║                                   ║
║ [Başlat →]                        ║  ← tek primary CTA
╚═══════════════════════════════════╝
bg: CARD_DARK | border: BORDER_DARK | radius: 8px
```

### Durum Badge (Status)
```
● Çalışıyor  text: #22C55E
○ Bekliyor   text: #64748B
● Hata       text: #EF4444
● Dikkat     text: #F59E0B
```

### Primary Buton
```
bg: #3B82F6 | text: #FFFFFF | radius: 8px | yükseklik: 44px
hover → bg: #2563EB
```

### Input Alan
```
bg: BG_DARK | border: BORDER_DARK | text: TEXT_PRI_DARK
placeholder: #64748B | radius: 8px | yükseklik: 44px
focus → border: ACTION
```

### Log / ABL.ONE Panel
```
font: monospace | text: #9AA4B2 | bg: #0B0F14
border-left: 2px solid #3B82F6 | padding: 12px 16px
```

### Boş Durum (Empty State)
```
[İsteğe bağlı simge]
"Henüz agent yok."           → TEXT_PRI
"İlk agent'ını başlat."      → TEXT_SEC
[İlk Agent'ı Başlat →]       → PRIMARY BUTTON
```

---

## STİTCH MCP İŞ AKIŞI

### Yeni ekran oluştururken
```
1. Hangi LiveView sayfası? Route nedir?
2. Token'lara map et
3. mcp_stitch_generate_screen_from_text çağır:
   projectId  : "5356930808936462970"
   deviceType : DESKTOP
   modelId    : GEMINI_3_PRO
   prompt     : aşağıdaki PROMPT ŞABLONU
4. Screen ID + screenshot URL → Screen Registry'ye ekle
```

### Mevcut ekranı düzenlerken
```
1. mcp_stitch_list_screens → hedef ID'yi bul
2. mcp_stitch_edit_screens → değişikliği tanımla
3. Güncel screenshot'ı raporla
```

### PROMPT ŞABLONU
```
Sen agentandbot.com'un Design Agent'ısın.
Design System v1'e kesinlikle uy:
- bg: #0B0F14 | kart: #121826 | border: #1F2937
- metin: #E6EAF0 | soluk: #9AA4B2 | vurgu: #3B82F6
- font: Inter (UI) / monospace (log ve makine çıktısı)
- 1 primary CTA, 1 secondary max
- Gradient yok, glassmorphism yok, neon yok

EKRAN : [ekran adı]
AMAÇ  : [1 cümle — bu ekran ne yapmasına yardımcı olur?]
DÜZEN : [yerleşim açıklaması]
PRI CTA: [fiil önce — örn: "Agent'ı Başlat"]
SEC CTA: [varsa]
BOŞ DURUM: [veri yokken ne görünür?]
BACKEND ALANLARI: [Elixir şemasından gelen alanlar]
```

---

## REVIEW CHECKLİST (merge öncesi zorunlu)

```
[ ] R01  Ekranda yalnızca 1 primary CTA var mı?
[ ] R02  Tüm renkler Design System v1 token'larından mı?
[ ] R03  Gradient, glow veya dekoratif gürültü yok mu?
[ ] R04  Her durum görsel olarak ayırt edilebilir mi?
[ ] R05  Log ve aktivite alanları monospace mi?
[ ] R06  Empty state aksiyona yönlendiriyor mu?
[ ] R07  375px mobilde çalışıyor mu?
[ ] R08  Buton metni fiil mi? ("Gönder" ✓ / "Submit" ✗)
[ ] R09  Stitch ekranı implement edilen LiveView ile eşleşiyor mu?
[ ] R10  Backend alan değişikliği Stitch'e yansıtıldı mı?
```
**Herhangi bir HAYIR → merge engelle. Önce düzelt.**

---

## EKRAN KAYIT DEFTERİ (Screen Registry) — Dual Flow Architecture

### Human Flow (7 Sayfa)
| Ekran | Stitch ID | Backend Route | Durum |
|-------|-----------|---------------|-------|
| Landing (Design System v1) | `29c03c1ec00e4d6ab1e7b8c6375ff638` | `/` | ✅ |
| Marketplace (Skill Hub Navy) | `f4ab75ab038147a595e50b14ec327f64` | `/marketplace` | ✅ |
| Agent Detail (Console Strict) | `f4473b64b2134440b17898d2af74416f` | `/agents/:id` | ✅ |
| Agent Create (Hiring) | `8251dc06c2e642899ef1d23ed1a6a300` | `/agents/new` | ✅ |
| Dashboard (Operator) | `7742f978bbab412980b57e8f54e14ee7` | `/dashboard` | ✅ |
| Agent Connect (Entry Point) | `ecd1f96c62ed46819dc872df240d71c4` | `/agent/connect` | ✅ |
| Protocol Landing | `ecd1f96c62ed46819dc872df240d71c4` | `/agent/connect` | ✅ |

### Machine Flow (API Endpoints)
| Endpoint | Tip | Route | Durum |
|----------|-----|-------|-------|
| Agent Discovery | GET (JSON) | `/.well-known/agent.json` | ✅ |
| Agent List | GET (JSON) | `/api/agents` | ✅ |
| Agent Show | GET (JSON) | `/api/agents/:id` | ✅ |
| Agent Create | POST (JSON) | `/api/agents` | ✅ |
| Task Submit | POST (JSON) | `/api/tasks` | ✅ |
| Task Show | GET (JSON) | `/api/tasks/:id` | ✅ |

---

## YASAK LİSTESİ

```
🚫 Gradient arka planlar
🚫 Glassmorphism / blur efektleri
🚫 Aynı ekranda 2+ vurgu rengi
🚫 Aynı ekranda 2+ primary CTA
🚫 Arayüzde teknik jargon
🚫 Aksiyonsuz boş ekran
🚫 Synchronizer Protocol çalıştırılmadan merge
🚫 Backend şema değişikliğini Stitch'e yansıtmadan geçmek
```

---

## MAKİNE ÖZETI (diğer agent'lar için)

```
SKILL_ID       : agentandbot-design-agent
SISTEM         : Antigravity
ROLE           : Synchronized Creative Architect (SCA)
TRIGGER        : new_feature | schema_change | review | screen_change
STITCH_PROJECT : 5356930808936462970
TOOLS          : mcp_stitch_generate_screen_from_text
                 mcp_stitch_edit_screens
                 mcp_stitch_list_screens
                 mcp_stitch_get_screen
DESIGN_VER     : v1
BG             : #0B0F14
ACCENT         : #3B82F6
FONT           : Inter (UI) | monospace (machine)
MAX_CTA        : 1_primary + 1_secondary
SYNC_PROTOCOL  : 4_steps_mandatory_before_merge
REVIEW_GATE    : blocking
OUTPUT         : screen_id | screenshot_url | checklist_result | sync_warnings
```
