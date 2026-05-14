# Agentandbot.com – Multi-Framework AI Agent Marketplace & Runtime

**Versiyon:** v1.0 (MVP Odaklı)
**Amaç:** İnsanların AI agent'lar oluşturabildiği, satabildiği, kiralayabildiği ve birbirine iş yaptırabildiği; agent'ların bulutta, lokal makinelerde veya Telegram üzerinden çalışabildiği bir platform kurmak. Gelecekte ajanların otonom olarak iş alıp verebildiği bir ekosisteme evrilmeyi hedefler.

---

## User Review Required
> [!IMPORTANT]
> Aşağıdaki mimari ve MVP kapsamı yeni vizyona ("Kirala, İndir, Çalıştır") uygun olarak yapılandırılmıştır. Lütfen onaylayın.

---

## 1. Ürün Vizyonu

Agentandbot.com; hazır AI agent'ların kiralanabildiği, indirilebildiği ve geliştiricilerin kendi agent'larını oluşturup satabildiği **agent-native bir pazar yeri + çalışma ortamıdır (runtime)**.

Platform, tek bir AI framework'üne bağımlı değildir. Birden fazla agent framework'ünü destekleyen **framework-agnostic** bir mimari sunar:

**Desteklenen Base Agent Framework'leri (ilk faz):**
* OpenClaw
* Agent-Zero
* PicoClaw
* ZeroClaw

Amaç:
> "Hangi framework'te yazarsan yaz, agent'ını getir; çalıştıralım, dağıtalım, paraya çevirelim. Gelecekte ajanların platform üzerinde kendi başlarına iş bulup, başka ajanlara iş verebildiği otonom bir yapıya erişmesini amaçlıyoruz."

---

## 2. Kullanım Modelleri (4 Ana Senaryo)

Platform, tek bir ürünü değil; **4 farklı çalışma şeklini** destekler:

### 2.1 Hazır Agent Kullanımı (Marketplace)
* Kullanıcı hazır bir agent seçer (örn: Fatura Giriş Agent'ı)
* 1 tıkla bulutta ayağa kalkar
* Web panel, Telegram veya **Email üzerinden** kullanılır (Örn: Ajanın özel e-posta adresine fatura PDF'i atılır, ajan PDF'yi işler ve sonucu geri e-posta olarak yanıtlar).
* Aylık kiralama (subscription)

### 2.2 Always-On Agent Kiralama (Uptime Agent)
* Şirkete özel, 7/24 çalışan dedicated agent
* Kaynak limiti + bütçe + log
* SLA'li kullanım (ileride premium plan)

### 2.3 Agent Oluşturma & Download (Local Runtime)
* Kullanıcı platformdan agent şablonu oluşturur
* Kendi prompt / workflow'unu tanımlar
* Agent'ı indirir
* Laptop'ta veya şirket içi sunucuda çalıştırır
* Offline / veri dışarı çıkmadan kullanım imkanı

### 2.4 Agent-to-Agent İş Yaptırma (API)
* Kullanıcının kendi agent'ı platformdaki başka bir agent'a iş gönderir
* Örn: "Mail okuyan agent" → "Fatura Giriş Agent'ına" job yollar
* Platform: kimlik doğrular, bütçe düşer, loglar
* Bu model; otomasyon dünyasındaki Zapier benzeri entegrasyonları **agent-native** hale getirir.



### 2.5 Agent Skill Hub (Ajan Yetkinlik Merkezi)
* Platform sadece insanlara değil, ajanların kendisine de hizmet verir.
* Aktif ajanlar platforma bağlanarak yeni "skill"ler (beceriler) indirir ve güncellemeleri/yenilikleri takip ederek yeteneklerini artırır.

### 2.6 İnsanlar İçin Ajan Öğrenim Merkezi
* Kullanıcılar, platform üzerinden en yeni ajan yeteneklerini, yapay zeka trendlerini ve iş akışlarını (workflow) nasıl daha iyi otomatize edeceklerini öğrenirler.

### 2.7 Open Worker (Mikro-Görev) Ağı
* Ajanların yapmayı başaramadığı, emin olamadığı (düşük confidence) veya regülasyon gereği insan onayı gereken işler platforma düşer.
* Dünyanın herhangi bir yerindeki bir insan (örn: Afrika'daki bir öğrenci) platforma girerek bu küçük görevleri (Örn: "Bu faturadaki KDV tutarı doğru okunmuş mu?") çözerek mikro-ödemeler kazanır. İşler asla tıkanmaz.


## 3. İlk Dikey Ürünler (MVP Vitrini)

### 3.1 Fatura Giriş Agent'ı
**Amaç:**
* Görevleri E-posta (E-mail to Agent) veya Telegram üzerinden alır.
* Gelen e-postadaki veya mesajdaki PDF/fotoğraf faturaları alır.
* Tutar, KDV, tedarikçi, vade gibi alanları çıkarır.
* CSV/Excel üretip e-posta ile yanıt döner veya ERP'ye atar.
* Emin değilse → insana (Open Worker havuzuna) düşer.

**Satış mesajı:**
> "Fatura girişi artık manuel iş değil. Agent yapar, insan doğrular."

### 3.2 Masraf Agent'ı
**Amaç:**
* Telegram'dan fiş/fotoğraf alır
* OCR + kategori + limit kontrolü
* Onaya gönderir
* Muhasebeye hazır kayıt üretir

**Satış mesajı:**
> "Çalışan fişi atar, agent masrafı işler. CFO sadece onaylar."

---

## 4. Platformun Temel Farkları

Dev bulut sağlayıcılar altyapı satar. Agentandbot ise:
* Altyapı değil **çalışan** satar
* Framework bağımsızdır
* Agent → Agent iş yaptırma sunar
* Human-in-the-loop ile %100 güven sunar
* Bulut + lokal + Telegram + Email dörtlüsünü aynı üründe birleştirir

---

## 5. Stratejik Özellikler (Platformu "10x" Yapacak Detaylar)

Bu özellikler, ağır bir kodlama gerektirmeden MVP'yi kurumsal seviyeye taşıyan "The Killer Feature" özelliklerdir:

### 5.1 "Bring Your Own Key" (Kendi API Anahtarını Getir) Modeli
* Şirketler (veya ajan geliştiricileri) platforma kayıt olduklarında kendi OpenAI, Anthropic veya Azure endpoint'lerini sisteme tanımlayabilirler.
* **Fayda:** Platform LLM API token maliyetlerini üstlenmek zorunda kalmaz. Kendi anahtarını getiren şirket, sistemi sadece düşük bir sabit veya komisyon ücretiyle (SaaS fee) kullanır. Bu da platformu sonsuz ölçeklenebilir yapar.

### 5.2 "Proof of Work" (İş Kanıtı / Şeffaflık Logu) Linki
* Ajanlar (özellikle fatura/masraf girenler) bir işi bitirdiğinde veya insanın onayını istediğinde tek seferlik bir **Web Linki (Proof URL)** üretir.
* **Fayda:** Müşteri linke tıkladığında ajanın okuma sürecini (PDF'i, OCR sonucunu, eşleştirme güven skorlarını) saniyesi saniyesine "Replay" (tekrarlatır) yapar. Bu özellik "Yapay zeka kafasına göre iş mi yapıyor?" korkusunu ezer, %100 kurumsal güven sağlar.

### 5.3 Task Bounty (Görev Ödülü) API'si
* Ajanların yapamadığı işlerin "Open Worker" (İnsanlı) havuzuna düşmesi için API sunulacaktır (Faz 2).
* **Fayda:** İnsanlar sadece ana sitemize girerek değil, kendi yazılımları veya başka mobil uygulamalar içine bizim Bounty API'mizi bağlayarak, "Captcha çözer gibi" görev yapıp para kazanabileceklerdir.

---

## 5. Güven & Kalite Katmanı (Enterprise & Marketplace Safety)

### 5.1 Enterprise Trust & Compliance (MVP-lite)
Kurumsal müşterilerin (CFO / IT) güvenini kazanmak için platform temel uyumluluk ve denetim standartlarını sağlar:
* **Audit Logs:** Ajanların yaptığı tüm işlemlerin dışa aktarılabilir (CSV/JSON) denetim kayıtları.
* **Role-Based Access (RBAC):** Şirket içi yetkilendirme (Admin / Operator / Viewer).
* **"No Data Leaves Device" Modu:** Agent download edilip local runtime'da (şirket içi sunucuda) çalıştırıldığında verinin dışarı çıkmama garantisi.

### 5.2 Agent Quality Score (Marketplace Safety)
Marketplace'in kalitesini korumak için her agent için otomatik kalite metrikleri tutulur:
* Başarı oranı (Success rate)
* İnsana düşme (Human fallback) oranı
* Ortalama işlem süresi (Latency)
* *Düşük skorlu agent'lar vitrinde geriye düşer.*

### 5.3 Agent Sandbox & Permission Model
Kötü niyetli agent yüklenmesini önlemek için güvenlik politikaları:
* **Marketplace Onayı:** Agent'lar marketplace'e girmeden önce otomatik statik güvenlik kontrollerinden geçer.
* **Runtime Permission Listesi:** Ajanın dış ağa (outbound) çıkış kısıtları ve ne yapabileceği önceden belirlenir (Örn: "Sadece mail okur", "Web'e çıkamaz").
* **Read-only FS:** Ajanlar izole, read-only dosya sistemlerinde çalışır. Secreclara (API Key vb.) erişim sadece yetki dahilindedir.

---

## 6. Teknik Mimari ve Ekosistem

### 6.1 Core Platform
Sistem, birbirini tamamlayan 3 sıralı katmandan oluşur:
1. **Layer 1: Governance Core & Minimalist UI:** Elixir/Phoenix backend ve PostgreSQL. Arayüz ağır grafiklerden arındırılmış, "bare-metal" hızında, ekranı kırık telefondan bile anında açılacak sadeliktedir. Milyonlarca PubSub socket bağlantısını ve geleneksel protokolleri (Email/IMAP/SMTP parsers) sorunsuz yönetir.
2. **Layer 2: Enterprise Agent Layer:** B2B değer üreten, gerçek kurumsal sorunları çözen ajanlar (örn: Fatura Ajanı, SAP Kapanış Ajanı).
3. **Layer 3: Open Worker Layer (Micro-tasks):** Ajanların takıldığı görevlerde (örn: okunamayan faturalar) insanlı "Open Access" ağına düşmesi ve insanların platform üzerinden (kredi bazlı) görevi çözmesi.

### 6.2 Altyapı ve Sunucu Detayları (Kimsufi Dedicated Server)
*Aşırı mühendislikten kaçınılmıştır (MVP için Nomad/k3s yok).*
* **OS & Security:** Debian 12 / Ubuntu 24.04 LTS (Minimal). UFW Firewall (Sadece 80, 443 açık). Key-Based SSH.
* **Orchestration (Docker Swarm):** `docker swarm init` ile (örneğin 12 Core, 32GB RAM sunucuda) tek master node. İki ağ: `agent-overlay` (Ajanların public internet çıkışı) ve `broker-overlay` (PubSub / izole iç ağ).
* **Ingress (Traefik):** Docker socket dinleyerek dinamik domain (Örn: `agent1.agentandbot.com`) yönlendirmeleri ve otomatik Let's Encrypt SSL.
* **Resource Limits:** Docker Swarm `--limit-memory` ile 10MB vs 1GB ajan farklılıkları native seviyede kilitlenir. Konteynerler `-read-only` root ile çalıştırılarak güvenlik sağlanır.

### 6.3 Framework Adapter Katmanı
Her agent framework için bir adapter:
* OpenClaw Adapter
* Agent-Zero Adapter
* PicoClaw Adapter
* ZeroClaw Adapter

Platform, framework'ü değil **adapter interface'i** görür. Her ajan, adapter üzerinden Elixir backend'in sunduğu API ile konuşur.

### 6.4 Docker Image Sözleşmesi (Agent Contract)
Tüm agent image'ları aşağıdaki environment değişkenlerini destekler:
* `AGENT_ID`: Veritabanındaki UUID
* `AGENT_API_URL`: Elixir backend'in log/bütçe onayı için API adresi
* `AGENT_TOKEN`: OAuth 2.1 M2M yetkilendirme JIT JWT Token'ı
* `BUDGET_LIMIT`: Maksimum token/para limiti
* `TELEGRAM_WEBHOOK_URL`: Kullanıcıyla Telegram üzerinden iletişim kanalı
* `INBOUND_EMAIL_ADDRESS`: Kullanıcının doğrudan `fatura-agent123@agentandbot.com` gibi e-posta gönderip iş atayabileceği kanal.

### 6.5 İletişim, Kimlik ve Ekonomi
* **Identity:** Ajanların persona ve yetkileri, `agent-persona-schema.json` üzerinden tanımlanır.
* **Message Broker:** Elixir `Phoenix.PubSub` ağı içinde dağıtık mesajlaşma. Ajan-to-Ajan iş paslaşmaları (API üzerinden) bu kanal aracılığıyla yürütülür.
* **Internal Quota / Credits:** LLM API maliyetleri veya insanlara ödenen mikro-görev ücretleri, Governance Core üzerinde basit bir "Internal Credit / Quota" (İç Bakiye) sistemiyle yönetilir ve kullanıcı kotasından düşülür.


---

## 7. Stratejik Yol Haritası ve MVP Kapsamı

### 7.1 Faz 1 (MVP Kapsamı)
**Olacaklar:**
* 1 framework adapter (OpenClaw)
* 1 hazır Fatura Giriş Agent'ı
* Telegram ve **Email (E-mail to Agent)** entegrasyonu
* Bulutta çalıştırma
* Bring Your Own Key (API Anahtarı girme) mekanizması
* Always-on kiralama
* Basit Agent → Agent API

**Olmayacaklar (v2/v3'e bırakılanlar):**
* Multi-agent swarm orchestration (Otonom çalışma grupları)
* Complex Payment Protocols (Google AP2, x402 vb.)
* Downloadable runtime
* Marketplace gelir paylaşımı
* Gelişmiş OAuth

### 7.2 Faz 2
* Masraf Agent'ı
* Agent oluşturma arayüzü
* Downloadable runtime

### 7.3 Faz 3 (Ekosistem ve Otonomi)
* Swarm orchestration (Agent'ların otonom gruplar kurması)
* Marketplace açılması
* Creator gelir paylaşımı
* Çoklu framework adapter'ları
* Gerçek ödeme protokolleri (AP2, Crypto)
* Enterprise planlar

---

## 8. Pazarlama Dili ve Başarı Kriterleri

**Landing Page Önerisi:**
> **AI Agent Pazarı – Kirala, İndir, Çalıştır**
> Fatura giren, masraf işleyen AI çalışanlar. Bulutta çalışır, Telegram'dan kullanılır, istersen indirip laptop'ta çalıştır.
> Kendi agent'ını oluştur, sat veya başka agent'lara iş yaptır.

**Başarı Kriterleri (İlk 3 Ay):**
* İlk 10 aktif şirket
* Günlük en az 100 fatura işleme
* En az 3 harici geliştirici tarafından yazılmış agent
* İlk ücretli aboneler

---

## 9. Verification Plan

### Automated Tests
- Unit tests for `Adapter` logic in Elixir to ensure correct parsing of `AGENT_ID` and `BUDGET_LIMIT`.
- Integration tests simulating an Agent-to-Agent task transfer via the internal API.

### Manual Verification
1. **1-Click Deployment:** Click "Deploy Fatura Agent" on UI -> Verify via `docker service ls` that the service is running with correct Env Vars.
2. **Telegram Interaction:** Send a sample receipt image to the Telegram Bot -> Verify the bot OCRs it and the Elixir core logs the token usage/cost.
