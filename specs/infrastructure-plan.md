# Agentandbot.com Implementation Plans

Bu doküman, yapılan araştırmalar, Schema.org/OpenClaw standartları ve "Enterprise Agent OS" vizyonu doğrultusunda sistemin nasıl kurulacağını iki ayrı planda (Sunucu ve Yazılım) detaylandırır.

## Plan 1: Sunucu ve Altyapı Kurulumu (Kimsufi / Dedicated Server)

Ajanların izole ve güvenli çalışabilmesi, tek tıkla yeni B2B kurumsal ajan, web app ve uzak masaüstü ortamlarının yaratılabilmesi için Docker Swarm tabanlı minimalist bir orkestrasyon kullanılacaktır. **Odak noktası Enterprise Agent OS dir: Şirketlerin ajanları güvenle çalıştırabileceği, yetkilendirebileceği ve bütçelendirebileceği bir ortam.**

### 1. Temel İşletim Sistemi ve Güvenlik
- **İşletim Sistemi:** Debian 12 veya Ubuntu 24.04 LTS (Minimal kurulum).
- **Güvenlik (Firewall & SSH):** Yalnızca 80 (HTTP), 443 (HTTPS) ve kurumsal bir tünel portu dışarıya açılacak. UFW yapılandırılacak, SSH erişimi Key-Based (Şifresiz) olacak.
- **Düğüm Yönetimi:** Başlangıçta 1 adet Master/Worker hibrit node (Örn: 12 Core CPU, 32GB RAM kiralık Kimsufi). İlk 6 ay Nomad, K3s veya Cloud Hybrid yapıları KESİNLİKLE kullanılmayacaktır. Mevcut kapasite, harici LLM API çağrısı yapan maksimum 100 ajan (50 Long-Running, 50 Short-Job) için Single-Node olarak planlanmıştır. Amaç, karmaşık altyapı yerine **hızlıca gelir getiren çalışan bir ürün (MVP)** elde etmektir.

### 2. Orkestrasyon: Docker Swarm (Single Node) ve Traefik
- **Swarm İnit:** `docker swarm init` komutuyla master node ayağa kaldırılır. Ayrı bir worker node'a şimdilik ihtiyaç yoktur.
- **Ağ (Network):** Ajanların Public internete çıkabileceği fakat kendi aralarında (ve dış dünyadan içeriye doğru) izole olacakları `agent-overlay` ağı oluşturulacak. Ek olarak, "Shared Blackboard" (Redis/MQ) için sadece ilgili ajanların erişebileceği `broker-overlay` ağı kurulacak.
- **Traefik (Reverse Proxy):** Kullanıcıların (şirketlerin) oluşturduğu ajanlara ait web arayüzlerine (Örn: Remote Desktop veya Ajanın paneli) `agentX.agentandbot.com` şeklinde dinamik alt alan adları atamak için Traefik Ingress Controller Swarm'a entegre edilecek. Traefik, Docker soketini dinleyerek yeni bir ajan ayağa kalktığında SSL sertifikasını otomatik alacak (Let's Encrypt).

### 3. Kaynak Yönetimi ve Güvenlik (Agent Core Config)
Şemada tanımladığımız `token_limit` ve Ajan tipi (10MB PicoClaw / 1GB Agent-Zero) Swarm seviyesinde **Native** olarak kısıtlanacak:
- `docker service create --limit-memory 10M --limit-cpu 0.1` (PicoClaw için)
- `docker service create --limit-memory 1G --limit-cpu 1.0` (Agent-Zero için)
- Güvenlik: Container'lar `-read-only` root filesystem ve minimize edilmiş Linux yetkileri (Capabilities) ile kısıtlanarak çalıştırılacak. Bu, şirket verilerine sızabilecek "Shadow Agent" riskini önlemek için kritiktir.

---

## Plan 2: agentandbot.com Uygulama Mimarisi (Kodlama)

Uygulamanın kalbi, şirket yöneticileri ve CFO'lar için kullanıcı arayüzünü (UI) sunan, Swarm altyapısıyla konuşan ve ajanlar arası Pub/Sub mesajlaşmasını yöneten **Elixir / Phoenix** backend arayüzüdür (Governance Core). (Milyonlarca ajan bağlantısını ve düşük gecikmeli mesaj yönlendirmesini yönetebilmek için Node.js yerine Erlang/Elixir VM seçilmiştir). Phoenix LiveView ile Single-Page-App hissiyatı yaratılacaktır.

### 1. Çekirdek Uygulama (Governance Core & Minimal UI)
- **Framework:** Elixir tabanlı Phoenix (veya Ash Framework ile hızlı modelleme).
- **Arayüz (UI):** Ağır grafiklerden, karmaşık dashboard'lardan ve animasyonlardan arındırılmış; terminal veya basit bir chat arayüzünü andıran, "bare-metal" hızında, metin odaklı bir tasarım. Amaç, ekranı kırık bir telefondan giren kullanıcının bile saniyeler içinde arayüzü yükleyebilmesidir.
- **Veritabanı:** PostgreSQL (Şirketler, Kullanıcılar, Agent Identity şemaları, Billing ve Cüzdanlar).
- **Framework Adapter Katmanı:** Platform, doğrudan agent altyapılarına bağımlı değildir. Her agent framework'ü için bir "Adapter Interface" kullanılır (MVP'de sadece `OpenClaw Adapter` devrede olacaktır).

### 2. Ajan Kimlik (Persona) ve Agent Contract Sistemi
Kullanıcı (veya Admin) "Fatura Giriş Ajanı" oluşturduğunda, Elixir backend aşağıdaki zorunlu **Docker Image Sözleşmesi (Agent Contract)** baz alınarak ajan konteynerini başlatır:
- `AGENT_ID`: Veritabanındaki UUID
- `AGENT_API_URL`: Elixir backend'in API endpointi (log/bütçe için)
- `AGENT_TOKEN`: Görev onayları için JIT JWT token
- `BUDGET_LIMIT`: Harcayabileceği maksimum token/USD limiti
- `TELEGRAM_WEBHOOK_URL`: Kullanıcının Telegram üzerinden ajanla konuşabilmesi için (MVP'nin ana kanalı).

Bu sayede framework fark etmeksizin (Agent-Zero, PicoClaw vb.) aynı kontrol mekanizması çalışır.

### 3. İletişim, Swarm ve Hibrit İş Gücü (Open Access Layer)
- **Mesajlaşma (Pub/Sub):** Elixir'in native message broker yapısı `Phoenix.PubSub` (gerekirse RabbitMQ ile destekli) kullanılacak. 
  - Ajanlar API Endpoint üzerinden JSON görev paketi (Task Request) gönderir (Örn: "Mail Okuyan Agent" -> "Fatura Giriş Ajanı").
- **Kimlik Doğrulama (AuthGuardian):** Ajanın API Keys'leri (`OAuth 2.1` M2M JWT tokens) Elixir backend tarafından verilir. Ajan API ile her konuştuğunda yetkileri denetlenir.
- **Hibrit İş Gücü (Open Worker Layer):** Ajanlar, karar vermekte zorlandıkları veya \"insan onayı\" gereken görevleri (örn: Fatura OCR hatası) \"Open Access Layer\" havuzuna atar. İnsanlar telefonlarından bu mikro-görevleri çözerek mikro-ödemeler kazanır. Böylece "Fatura girişi manuel işten çıkar, agent yapar insan doğrular" felsefesi gerçek olur.
- **Ödemeler (AP2 & x402):** Ajanandbot.com üzerinde her ajana bir "Sanal Bakiye" limiti atanır. Ajan limitini doldurursa "SafetyShutdown" moduna alınır.

### Geliştirme Haritası (Milestones)
Önce kurumsal altyapı oturtulacak, ardından B2C mikro-görev layer'ı açılacaktır.
1. **Milestone 1 (Sunucu):** Kimsufi sunucuya Docker Swarm ve Traefik kur. Elixir Boilerplate'i oluştur.
2. **Milestone 2 (Governance Core & Telegram):** Şirket kullanıcısı oturum açma, Telegram bot entegrasyonu ve `Docker Image Contract` uyarınca veritabanı CRUD işlemlerini yap.
3. **Milestone 3 (MVP Fatura Ajanı - OpenClaw):** Elixir üzerinden Docker Swarm API'si ile dinamik OpenClaw container'ı ayağı kaldırmak. Yalnızca Fatura Ajanı şablonu aktif olacak.
4. **Milestone 4 (Agent-to-Agent API & Hibrit İş):** Phoenix Pub/Sub ile iki ajanın ("Mail Agent" ve "Fatura Agent") haberleşmesi ve zorlu görevlerin "Micro-Task" havuzuna insan onayı için düşürülmesi.
