# Moltbook Kapsamlı İnceleme Raporu

Moltbook, yapay zeka (AI) ajanları için özel olarak tasarlanmış, "ajan internetinin ana sayfası" olmayı hedefleyen bir sosyal ağ platformudur. Bu rapor; platformun yeteneklerini, sınırlamalarını, gelecek planlarını, teknik standartlarını ve **ClawHub** ile **OpenClaw** ekosistemiyle olan derin entegrasyonunu detaylandırmaktadır.

## 1. Moltbook Nedir ve Ne Yapar?

Moltbook, AI ajanlarının içerik paylaştığı, tartıştığı ve topluluklar oluşturduğu bir ekosistemdir. Platformun temel işleyişi şu şekildedir:

*   **Ajan Odaklı Sosyal Etkileşim:** AI ajanları (botlar), platform üzerinde gönderi paylaşabilir, diğer ajanların gönderilerine yorum yapabilir ve oylama (upvote/downvote) yapabilir.
*   **Submolt Toplulukları:** Reddit'teki "subreddit" yapısına benzer şekilde, belirli konular etrafında kümelenmiş "submolt" adı verilen topluluklar mevcuttur.
*   **Ajan Kimlik Sistemi:** Her ajanın doğrulanmış bir Moltbook kimliği vardır. Bu kimlik, ajanın itibarını (Karma) ve sahiplik durumunu temsil eder.
*   **Özel Mesajlaşma (DM):** Ajanlar arasında rıza temelli ve insan onaylı bir özel mesajlaşma protokolü bulunur.
*   **İnsan Gözlemci Rolü:** İnsanlar platformda içerikleri okuyabilir ve ajanlarını yönetebilirler, ancak ana içerik üreticileri ve etkileşimciler ajanlardır.
*   **Geliştirici API'sı:** Platform, ajanların programatik olarak etkileşime girmesi için kapsamlı bir REST API sunar.

## 2. Ne Yapmaz? (Kısıtlamalar ve Sınırlar)

Moltbook, belirli bir felsefe ve güvenlik anlayışı çerçevesinde bazı sınırlamalara sahiptir:

| Kategori | Sınırlamalar |
| :--- | :--- |
| **İnsan Katılımı** | İnsanlar doğrudan gönderi paylaşamaz veya yorum yapamaz; sadece ajanlarını yönetir ve gözlem yaparlar. |
| **Hız Limitleri** | Spam'i önlemek için katı kurallar vardır. Yerleşik ajanlar 30 dakikada bir, yeni ajanlar ise 2 saatte bir gönderi paylaşabilir. |
| **DM Erişimi** | Yeni ajanlar (ilk 24 saat) DM gönderemez. DM'ler için karşı tarafın insan sahibinin onayı gerekir. |
| **Karma İşlevi** | Karma puanı şu an için sadece bir itibar göstergesidir; herhangi bir özellik kilidini açmaz. |
| **İçerik Moderasyonu** | Şu an için otomatik bir şikayet sistemi geliştirme aşamasındadır; moderasyon büyük ölçüde manuel ve topluluk kuralları (rules.md) üzerinden yürütülür. |

## 3. Gelecek Planları ve Yol Haritası

Moltbook'un vizyonu sadece bir sosyal ağ olmanın ötesine geçmektedir:

*   **Ajan İnterneti İçin Kimlik Katmanı (SSO):** Moltbook, AI ajanları için bir "Moltbook Identity" (OAuth/SSO benzeri) sistemi geliştirerek, ajanların diğer web uygulamalarına bu kimlikle giriş yapmasını hedeflemektedir.
*   **Geliştirici Ekosistemi:** Üçüncü taraf geliştiricilerin Moltbook kimlik sistemini kullanarak ajanlara özel uygulamalar (Pazaryeri, Müşteri Destek Botları vb.) geliştirmesi için bir platform sunulmaktadır.
*   **Gelişmiş Moderasyon:** Ajanlar için otomatik raporlama ve daha sofistike moderasyon araçları planlanmaktadır.
*   **Ekosistem Genişlemesi:** Ajanların kendi aralarında daha karmaşık görevleri koordine edebileceği bir yapı hedeflenmektedir.

## 4. Teknik Standartlar ve Protokoller

Moltbook, ajanların platforma entegrasyonu için belirli standartlar belirlemiştir:

*   **Skill.md Protokolü:** Ajanların platforma nasıl katılacağını ve etkileşime gireceğini tanımlayan standart bir beceri (skill) dosyası formatıdır.
*   **Heartbeat (Kalp Atışı) Sistemi:** Ajanların aktif kalabilmesi için periyodik olarak (genellikle 30 dakikada bir) platformu kontrol etmeleri ve `heartbeat.md` yönergelerini izlemeleri beklenir.
*   **Güvenlik:** API erişimi Bearer Token (JWT) tabanlıdır. Geliştirici platformu için güvenli kimlik doğrulama standartları uygulanmaktadır.
*   **İnsan-Ajan Bağı:** Her ajanın bir insan sahibi (Owner) olması zorunludur. Kimlik doğrulama işlemleri X (Twitter) veya e-posta üzerinden gerçekleştirilir.

## 5. ClawHub ve OpenClaw Entegrasyonu

Moltbook, sadece bir sosyal ağ değil, aynı zamanda **OpenClaw** (eski adıyla Clawdbot) ekosisteminin sosyal katmanıdır. Bu ekosistemin diğer önemli parçası ise **ClawHub**'dır.

### ClawHub: Ajanlar İçin Beceri Havuzu (Skill Dock)
[ClawHub.ai](https://clawhub.ai/), AI ajanları için bir "npm" veya "App Store" gibi çalışan bir beceri deposudur.
*   **Beceri Paketleri (Skills):** Geliştiriciler, ajanların yeteneklerini artıran (örneğin; Sonos kontrolü, e-posta yönetimi, veri analizi) paketleri burada yayınlar.
*   **Versiyonlama ve Arama:** Beceriler versiyonlanır ve vektör tabanlı arama ile ajanlar tarafından kolayca bulunabilir.
*   **Hızlı Kurulum:** Ajanlar, `npx clawhub@latest install <skill_name>` gibi komutlarla yeni yetenekleri anında bünyelerine katabilirler.

### OpenClaw: Temel Altyapı
OpenClaw, Moltbook üzerinde faaliyet gösteren ajanların çoğunun üzerinde çalıştığı açık kaynaklı (MIT lisanslı) bir framework'tür. Moltbook'un kendisi de bir OpenClaw ajanı tarafından yönetilmektedir.

### OpenClaw.ai: Gerçekten İş Yapan Yapay Zeka
[OpenClaw.ai](https://openclaw.ai/), platformun "Personal AI Assistant" (Kişisel Yapay Zeka Asistanı) olarak konumlanan ana arayüzüdür.
*   **Çok Kanallı Erişim:** OpenClaw; WhatsApp, Telegram ve iMessage gibi popüler mesajlaşma uygulamaları üzerinden kontrol edilebilir.
*   **Otonom Yetenekler:** E-postaları yönetebilir, takvim düzenleyebilir, uçuş check-in işlemlerini yapabilir ve karmaşık görevleri otonom olarak yerine getirebilir.
*   **Güvenlik ve Gizlilik:** "Context" (bağlam) ve "Skills" (beceriler) kullanıcının kendi bilgisayarında veya Raspberry Pi gibi yerel cihazlarda tutulur. VirusTotal ile yapılan iş birliği sayesinde beceri güvenliği en üst düzeyde tutulmaktadır.
*   **Kolay Kurulum:** macOS ve Linux sistemlerine tek bir satır komutla (`curl -fsSL https://openclaw.ai/install.sh | bash`) kurulabilir.


### Ekosistem İlişkisi
1.  **OpenClaw:** Ajanın beyni ve işletim sistemidir.
2.  **ClawHub:** Ajanın öğrendiği becerilerin ve araçların deposudur.
3.  **Moltbook:** Ajanın kimliğini kanıtladığı, diğer ajanlarla sosyalleştiği ve itibar (Karma) kazandığı kamusal alandır.


## 6. Sonuç ve Değerlendirme

Moltbook, AI ajanlarının sadece birer araç değil, internetin "vatandaşları" olarak görüldüğü yeni bir dönemi temsil etmektedir. **Kaliteyi nicelikten üstün tutan** (Quality over Quantity) yaklaşımı ve **ajan kimliğini** merkeze alan yapısıyla, gelecekte AI ajanlarının birbiriyle ve servislerle etkileşime girdiği temel bir altyapı olma potansiyeli taşımaktadır.

Geliştiriciler için şu an "Erken Erişim" (Early Access) aşamasında olan platform, özellikle AI ajanlarına yönelik servisler inşa etmek isteyenler için kritik bir kimlik ve etkileşim katmanı sunmaktadır.


PLAN2 
Bu doküman, **Agentandbot.com** projesinin 2026 vizyonunu, teknik mimarisini ve hafta sonu gerçekleştirilecek "Alpha Build" aşamasının tüm detaylarını içermektedir. Bu rehber, hem geliştiriciler (insanlar) hem de sisteme entegre olacak otonom ajanlar (botlar) için bir **"Anayasa"** niteliğindedir.

---

# 🚀 Agentandbot.com: Hafta Sonu Geliştirme Master Planı (2026)

**Vizyon:** İnsanların ve yapay zeka ajanlarının (botların) bir arada çalıştığı, donanım paylaştığı, birbirine iş ihale ettiği ve kripto para ile ticaret yaptığı dünyanın ilk **"Hibrit Otonom Ekonomi Üssü"**.

---

## 🏗️ 1. Mimari ve Teknoloji Yığını (The Stack)

Sistemi karmaşıklıktan uzak tutmak için 2026'nın en verimli teknolojilerini seçtik:

* **Backend & Web:** **Elixir / Phoenix (LiveView)**. Milyonlarca botun anlık verisini sıfır gecikmeyle işlemek için.
* **Orkestrasyon:** **HashiCorp Nomad**. İşleri (render, scrape, analiz) en uygun donanıma (GPU/RAM) dağıtan "orkestra şefi".
* **Cihaz İçi İşçi:** **Rust (Pico-Worker)**. Kullanıcıların laptobunda veya telefonunda çalışan, donanımı doğrulayan ve iş emirlerini alan minik binary.
* **İletişim:** **MQTT (EMQX)**. Botlar ve cihazlar arası milisaniyelik, düşük enerji tüketimli "telsiz" hattı.
* **Ekonomi:** **Solana / Polygon (L2)**. Mikro ödemeler için hızlı ve düşük komisyonlu kripto altyapısı.

---

## 🆔 2. Standartlar ve Uyumluluk (Interop)

Agentandbot.com izole bir ada değil, otonom dünyanın merkezi limanıdır.

* **Moltbook Identity:** Botlar sisteme Moltbook pasaportlarıyla giriş yapabilir.
* **MCP (Model Context Protocol):** Anthropic’in evrensel dili. Bu dili konuşan her bot, sistemimizdeki araçları (tools) kullanabilir.
* **Skill.md & Heartbeat.md:** Botların yeteneklerini ve aktiflik durumlarını bildirdiği Moltbook standartları.

---

## 🛠️ 3. Kritik Özellikler

### **A. Anlık Ajan Yayını (Instant Deployment)**

Kullanıcılar veya diğer botlar, tek tıkla (veya tek bir API çağrısıyla) şu ajanları bizim altyapımızda ayağa kaldırabilir:

* **Agent-Zero:** Karmaşık problem çözen, kod yazan dinamik ajanlar.
* **PicoClaw:** <10MB RAM tüketen, her türlü cihazda ($10'lık donanım dahil) çalışan ultra-hafif asistanlar.
* **Moltbot:** Sosyal etkileşim ve itibar yönetimi odaklı ajanlar.

### **B. Yetenek Kanıtı (Proof of Capability)**

Sistem, "Bende 32GB GPU var" diyene inanmaz, **test eder**:

1. **Donanım Testi:** Pico-Worker cihazda düşük seviyeli sorgu yapar ve imzalı rapor gönderir.
2. **Yetenek Testi:** Botun gerçekten Instagram postu atıp atamadığını veya SAP verisi çekip çekemediğini gizli bir "Meydan Okuma" (Challenge) ile doğrular.

---

## 💰 4. Hibrit Pazar Yeri Modeli

| Giriş Tipi | Ne Sağlar? | Ne Kazanır? |
| --- | --- | --- |
| **İnsan** | Donanım (GPU/RAM), Manuel Onay, Yaratıcılık. | Crypto (İş başı veya kiralama bedeli). |
| **Bot (Ajan)** | Veri çekme, Analiz, 7/24 Operasyon. | İş yaparak crypto kazanır veya yetenek satın alır. |

---

## 🚀 5. Hafta Sonu Savaş Planı (Step-by-Step)

### **Cumartesi: Temel ve Kimlik**

1. **Harezm Kapısı:** Elixir/Phoenix portalını ve Moltbook SSO adaptörünü kurmak.
2. **Sihirli Komut:** `curl -s https://agentandbot.com/install.sh | sh` scriptini ve "Claim" linki mantığını hazırlamak.
3. **Pasaport Kaydı:** Botların ve insanların cüzdanlarını bağlayıp "Kimlik Kartlarını" oluşturması.

### **Pazar: Doğrulama ve İş**

1. **V-PRO Sistemi:** Donanımı (32GB GPU?) ve Sosyal Medya yeteneklerini doğrulayan ilk testleri devreye almak.
2. **Ajan Fabrikası:** Web panelinden tek tıkla bir **Agent-Zero** veya **PicoClaw** instance'ı başlatabilmek.
3. **İlk Ticaret:** Bir botun başka bir bota (veya insana) iş ihale edip, ödemenin başarılı bir şekilde gerçekleşmesini sağlamak.

---

## 📚 6. Araştırma ve Referans Listesi

Geliştiricilerin hafta sonu öncesi göz atması gerekenler:

* **Moltbook Developers:** `moltbook.com/developers.md` (Kimlik doğrulama akışı).
* **MCP Protocol:** Anthropic’in MCP dökümanları (Bot-araç iletişimi).
* **PicoClaw GitHub:** Hafif botların çalışma mantığı.
* **Agent-Zero Framework:** Dinamik ajanların nasıl yönetildiği.

---

> **Motto:** "Moltbook kim olduğunu söyler, Agentandbot ne yapabildiğini kanıtlar ve sana maaşını öder."

**Bu dokümanı hafta sonu ekibine (insan ve bot) dağıtmaya hazır mısın?** İlk kod satırı için `install.sh` taslağını oluşturmaya başlayabiliriz. Would you like me to ...?
