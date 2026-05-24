# 100 AI Agent İçin Ölçeklenebilir Kurulum ve Yönetim Stratejisi

100 farklı agent hesabı açmak, sadece 100 e-posta adresi bulmaktan çok daha karmaşık bir süreçtir. Platformların (TikTok, Instagram, LinkedIn) gelişmiş bot tespit sistemlerini aşmak için **izolasyon**, **doğrulama** ve **davranışsal ısınma** stratejilerini uygulamanız gerekir.

## 1. E-posta Yönetimi: 100 Adres Gerekli mi?

Evet, her hesap için benzersiz bir e-posta adresi gereklidir. Ancak bunu yönetmenin akıllı yolları vardır:

*   **Kendi Alan Adınız (Custom Domain):** `agent1@sirketiniz.com`, `agent2@sirketiniz.com` şeklinde 100 adet e-posta yönlendirmesi (alias) oluşturun. Tüm mailler tek bir ana kutuya düşer, böylece yönetimi kolaylaşır.
*   **Gmail "+" Taktiği:** Bazı platformlar `isim+agent1@gmail.com` formatını kabul eder, ancak gelişmiş sistemler bunu tek bir hesap olarak algılayıp toplu ban atabilir. **Öneri:** Kendi alan adınızı kullanmak en güvenli yoldur.

## 2. Telefon Doğrulaması (SMS) Sorunu

Platformlar genellikle kayıt aşamasında veya şüpheli bir durumda telefon numarası ister. 100 fiziksel SIM kart almak yerine şu profesyonel çözümleri kullanmalısınız:

| Çözüm Türü | Önerilen Servisler | Avantajı |
| :--- | :--- | :--- |
| **Non-VoIP SMS Servisleri** | SMSPool, SMSPva, Grizzly SMS | Gerçek sim kart numaralarıdır, platformlar tarafından engellenmez. |
| **Sanal Numara (Kiralık)** | MoreMins, Quackr | Numarayı belirli bir süre (örneğin 1 ay) kiralayarak ilerideki doğrulamaları da alabilirsiniz. |

> **Kritik Uyarı:** Ücretsiz "Receive SMS Online" sitelerini asla kullanmayın; bu numaralar kara listededir ve hesaplarınız anında kapatılır.

## 3. İzolasyon: Banlanmayı Önleyen Altın Üçlü

100 hesabı aynı bilgisayardan ve aynı internetten açarsanız, platformlar bunları saniyeler içinde ilişkilendirip toplu ban atar. Bunu önlemek için şu yapıyı kurmalısınız:

### A. Anti-Detect Browser (Anti-Tespit Tarayıcı)
Her hesap için farklı bir "cihaz parmak izi" (fingerprint) oluşturur.
*   **Önerilen Araçlar:** AdsPower, Multilogin, Dolphin{anty}.
*   **İşlevi:** Her agent sanki farklı bir bilgisayar, farklı ekran çözünürlüğü ve farklı bir tarayıcı kullanıyormuş gibi görünür.

### B. Proxy (IP İzolasyonu)
Her hesaba özel bir IP adresi atanmalıdır.
*   **Mobil Proxy (4G/5G):** En güvenlisidir. Binlerce gerçek kullanıcıyla aynı IP havuzunu paylaştığınız için platformlar bu IP'leri engelleyemez (CGNAT teknolojisi).
*   **Residential Proxy (Konut Tipi):** Gerçek ev interneti gibi görünür. 100 hesap için maliyet/performans dengesi sağlar.

### C. Hesap Isınma (Warm-up) Süreci
Yeni açılan bir hesapla anında 100 kişiye mesaj atmak "bot" damgası yemenize neden olur.
*   **1-3. Gün:** Sadece ana sayfada gezinin, videoları izleyin.
*   **4-7. Gün:** Birkaç hesabı takip edin, 1-2 beğeni yapın.
*   **2. Hafta:** İlk içerik paylaşımına başlayın.

## 4. Özet Uygulama Planı

1.  **Altyapı:** Bir **AdsPower** veya **Dolphin{anty}** hesabı açın.
2.  **Proxy:** 100 adet **Residential Proxy** veya 10-20 adet (rotasyonlu) **Mobile Proxy** satın alın.
3.  **E-posta:** Kendi domaininiz üzerinden 100 adet alias (takma ad) oluşturun.
4.  **Kayıt:** Her tarayıcı profilinde bir proxy tanımlayın ve SMSPool gibi bir servisten tek kullanımlık numara alarak kayıt olun.
5.  **Otomasyon:** Kayıttan sonra agent'larınızı bu profillere bağlayarak (API veya tarayıcı otomasyonu ile) ısınma sürecini başlatın.

Bu yapı ile 100 agent'ı platformların radarına takılmadan profesyonel bir şekilde yönetebilirsiniz.
