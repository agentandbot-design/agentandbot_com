# Harezm Ekosistemi - E-Any.Online Dahili Araç Kayıt Defteri (Internal Tools Registry) Uygulama Planı

Bu belge, **agentandbot.com** Phoenix LiveView (`governance_core`) backend katmanında, `e-any.online` altyapısı üzerinde barındırılan iç servislerin (Ollama, Windmill, SiYuan, Nginx Proxy vb.) güvenli, denetlenebilir ve otonom ajanlar tarafından sorgulanabilir şekilde kaydedilmesini sağlayan **Internal Tools Registry** altyapısının tasarımını içerir.

---

## 🗺️ Mimari ve Güvenlik Seviyeleri

Ajanların ve holding operasyon ekibinin hangi aracın nerede çalıştığını, hangi Docker konteynerini kullandığını ve erişim yetkilerini (scopes) görmesini sağlayacağız. **SECURITY FIRST** prensibi gereğince:
*   API yanıtlarında veya veritabanında **hiçbir şekilde gerçek şifre/token tutulmayacaktır.**
*   Bunun yerine, gizli anahtarlar 1Password/Bitwarden gibi harici cüzdanları işaret eden `vault://...` referansları (`secrets_ref`) olarak saklanacaktır.
*   Ajanlara açılan genel API (`/api/internal-tools`) bu referansları (`secrets_ref`) da tamamen gizleyecek, sadece metadata ve yetki kapsamlarını (allowed scopes) dönecektir.

---

## 🔮 Önerilen Değişiklikler (Proposed Changes)

### 1. Veritabanı Katmanı (Ecto Migrations & Schemas)

#### [NEW] priv/repo/migrations/20260522113000_create_internal_tools.exs
- `internal_tools` tablosunu oluşturan göç (migration) dosyası.

#### [NEW] lib/governance_core/internal_tools/internal_tool.ex
- `InternalTool` Ecto şeması. `changeset/2` ile tüm kuralları ve benzersiz `slug` kısıtını doğrular.

---

### 2. İş Mantığı Katmanı (Context & YAML Synchronizer)

#### [NEW] lib/governance_core/internal_tools.ex
- `GovernanceCore.InternalTools` bağlam (context) modülü:
  - `list_internal_tools/0`, `get_internal_tool/1`, `get_internal_tool_by_slug/1` CRUD işlemleri.
  - Bağımlılık şişmesini önlemek için harici kütüphane kullanmayan, hafif, regex tabanlı bir satır içi YAML parse edici (`parse_yaml/1`) modül içi yardımcı olarak kodlanacaktır.
  - `sync_from_yaml/1` fonksiyonu projenin `ops/internal_tools.example.yml` dosyasını okuyup veritabanına otomatik olarak işleyecektir.

#### [MODIFY] lib/governance_core/application.ex
- Uygulama ayağa kalktığında (`start/2` bloğunda), veritabanındaki kayıtların YAML dosyasındaki güncel durum ile senkronize olmasını tetikleyen satır eklenecektir.

---

### 3. API Katmanı (Agent-Readable Endpoints)

#### [MODIFY] lib/governance_core_web/router.ex
- `/api` scope'una yeni dahili araç API rotaları eklenecek:
  ```elixir
  get "/internal-tools", Api.InternalToolController, :index
  get "/internal-tools/:slug", Api.InternalToolController, :show
  ```
- `/` (browser) scope'una insan yönetim paneli eklenecek:
  ```elixir
  live "/tools/internal", InternalToolsLive
  ```

#### [NEW] lib/governance_core_web/controllers/api/internal_tool_controller.ex
- `Api.InternalToolController` modülü:
  - `index` ve `show` aksiyonları.
  - Çıktı paketinde cüzdan referansları (`secrets_ref`) kesinlikle dışarı sızdırılmayacak, sadece güvenli alanlar dönecektir.

---

### 4. Kullanıcı Arayüzü Katmanı (Phoenix LiveView Dashboard)

#### [NEW] lib/governance_core_web/live/internal_tools_live.ex
- **`/tools/internal`** sayfasında:
  - Arama (search) ve kategoriye göre dinamik filtreleme.
  - Güvenli görsel kart tasarımları, durum renk kodları (healthy = green, restarting = orange vb.).
  - Ajan erişim kısıtlamalarını ve allowed scopes bilgilerini gösteren modern, premium koyu tema paneli.

---

## 🧪 Doğrulama Planı (Verification Plan)

### Otomatik Testler (Automated Tests)
1. `test/governance_core/internal_tools_test.exs`: YAML dosyasından okuma, veritabanına aktarma, CRUD ve schema kısıtlarını doğrular.
2. `test/governance_core_web/controllers/api/internal_tool_controller_test.exs`: `/api/internal-tools` rotasını sorgular ve `secrets_ref` alanının sızdırılmadığını doğrular.
3. `test/governance_core_web/live/internal_tools_live_test.exs`: Canlı arayüzün (LiveView) doğru şekilde render edildiğini kontrol eder.

Çalıştırılacak test komutu:
```powershell
$env:TEMP='C:\tmp'; $env:TMP='C:\tmp'; mix test
```
