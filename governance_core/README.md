# GovernanceCore

**GovernanceCore**, agentandbot.com platformunun Elixir/Phoenix LiveView tabanlı backend yönetim çekirdeğidir. AI agent kimlik yönetimi, görev orkestrasyon ve platform governance katmanını sağlar.

## 🏗️ Teknoloji Stack

- **Backend**: Elixir 1.15+ / Phoenix 1.8 (LiveView)
- **Veritabanı**: SQLite (geliştirme) / PostgreSQL (prodüksiyon)
- **Stil**: Tailwind CSS v4
- **HTTP Client**: Req
- **CI/CD**: GitHub Actions + Jules AI Code Review

## 🚀 Hızlı Başlangıç

### Gereksinimler

- Elixir ~> 1.15
- Erlang/OTP 26+
- Node.js 18+ (asset build için)

### Kurulum

```bash
# Bağımlılıkları yükle ve veritabanını hazırla
mix setup

# Geliştirme sunucusunu başlat
mix phx.server
```

Sunucu başladıktan sonra [`localhost:4001`](http://localhost:4001) adresinden erişebilirsiniz.

Alternatif olarak IEx içinde başlatabilirsiniz:

```bash
iex -S mix phx.server
```

### Ortam Değişkenleri

```bash
cp .env.example .env
# .env dosyasını kendi değerlerinizle doldurun
```

Gerekli değişkenler için `.env.example` dosyasına bakın.

## 🔧 Geliştirme Komutları

```bash
# Testleri çalıştır
mix test

# Kod kalite kontrolü (commit öncesi)
mix precommit

# Veritabanını sıfırla
mix ecto.reset

# Asset build
mix assets.build
```

## 📁 Proje Yapısı

```
governance_core/
├── lib/
│   ├── governance_core/        # İş mantığı (contexts, schemas)
│   └── governance_core_web/    # Phoenix web katmanı (LiveViews, controllers)
├── priv/
│   ├── repo/migrations/        # Ecto migration dosyaları
│   └── static/                 # Statik dosyalar
├── test/                       # ExUnit testleri
├── config/                     # Ortam konfigürasyonları
└── assets/                     # JS/CSS kaynakları
```

## 🤖 Jules AI Code Review

Bu proje, otomatik kod review için **Jules** entegrasyonu içerir:

- **Günlük review**: Her gece 00:00 TR saatinde çalışır
- **Güvenlik taraması**: Her Pazartesi sabahı
- **Push trigger**: `main` branch'e her push'ta

GitHub Actions workflow'ları `.github/workflows/` altında bulunur.  
`JULES_API_KEY` secret'ını GitHub repo ayarlarından eklemeniz gerekmektedir.

## 📋 Geliştirme Kuralları

Detaylı geliştirme kuralları için [`AGENTS.md`](AGENTS.md) dosyasına bakın.

Önemli notlar:
- HTTP istekleri için **her zaman** `Req` kullanın (HTTPoison kullanmayın)
- Commit öncesi `mix precommit` çalıştırın
- LiveView stream'leri büyük koleksiyonlar için zorunludur

## 🐳 Docker ile Çalıştırma

```bash
docker-compose up
```

## 🎮 KADRO & DNA Portability (Brain Sync)

Bu proje, agentandbot.com portalındaki **KADRO (Ajan İşe Alma, Seçim ve Kariyer)** sistemini destekler. Ajanların gelişim istatistiklerini, 1-Click bulut sandbox dağıtımlarını ve sunucular arası beyin senkronizasyonunu (DNA Portability) içerir.

### Özellikler

1. **KADRO Kariyer İlerlemesi (Gamification)**:
   - Ajanlar tamamladıkları her bir görevden **+50 XP** kazanır.
   - Ajan seviyeleri şu formülle hesaplanır: `Level = (XP / 100) + 1`.
   - Görev sayısına ve seviyelere göre özel Başarımlar (Achievements) açılır:
     - `"İlk Kan"`: 1 tamamlanan görev
     - `"Veteran"`: 5 tamamlanan görev
     - `"Yükselen Yıldız"`: Seviye 3+
     - `"Kod Mimarı"`: Seviye 5+
     - `"Yapay Zeka Dehası"`: Seviye 10+
   
2. **1-Click Sandbox ve Hostinger Dağıtımı**:
   - Platform içi Sandbox dağıtımı (`/agents/:id/deploy`), ajanın hosting modunu `"managed"` olarak günceller ve dinamik bir terminal log akış simülasyonu sonrasında ajana otomatik olarak benzersiz bir container endpoint URL'i atar.
   - Hostinger Docker VPS şablonları (`hermes-agent`, `agent-zero`, `openclaw`) üzerinden dış sunuculara yönlendirme desteği mevcuttur.

3. **DNA Beyin Senkronizasyonu (Portability)**:
   - Ajan gelişim verileri (`/agents/:id/brain_sync`) JSON formatında dışa aktarılabilir (`Export DNA`).
   - Sürükle-bırak uploader ile `.json` uzantılı DNA dosyaları sisteme yüklenip ajanın son beyin/gelişim istatistikleri senkronize edilebilir (`Import DNA`).

## 🔗 Kaynaklar

- [Phoenix Framework](https://www.phoenixframework.org/)
- [Phoenix LiveView](https://hexdocs.pm/phoenix_live_view)
- [Elixir Forum](https://elixirforum.com/c/phoenix-forum)
- [agentandbot.com](https://agentandbot.com)
