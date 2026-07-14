# Lessons Learned — agentandbot.com

## Session: 2026-02-22

### Lesson 1: DRY — Agent Veri Tekrarı
- **Hata**: Agent verisi `marketplace_live.ex`, `agent_detail_live.ex`, `api/agent_controller.ex` içinde 3 kez tekrarlandı
- **Kural**: Shared data her zaman tek bir kaynak modülde olmalı (`GovernanceCore.Agents`)
- **Düzeltme**: Merkezi bir context modülü oluştur, LiveView ve controller'lar oradan çeksin

### Lesson 2: Verification — Port/DB Sorunlarını Çözme
- **Hata**: `mix test` ve dev server başlatılamayınca durumu sadece rapor ettik
- **Kural**: Verification engellerini otonom çöz — port bul, DB'siz test yaz, alternatif doğrulama bul
- **Düzeltme**: `mix compile --warnings-as-errors` yeterli değil, en azından unit testler çalışmalı

### Lesson 3: Stitch MCP — Config ≠ Bağlantı
- **Hata**: MCP config'e eklendi ama IDE yeniden başlatılmadığı için bağlanamadık
- **Kural**: MCP server eklendiğinde her zaman bağlantı doğrulaması yap (`list_resources`)

## Session: 2026-05-22

### Lesson 4: Plan First For Architectural Changes
- **Hata**: CV Generator ve internal tool registry gibi mimari kararlar geldiğinde hemen uygulamaya geçildi; kullanıcının istediği plan/check-in ritmi yeterince erken uygulanmadı.
- **Kural**: 3+ adım, rota/API/migration veya dosya temizliği içeren her işte önce `tasks/todo.md` içine checkable plan yaz, sonra kullanıcı onayı bekle.
- **Düzeltme**: Uygulamaya devam etmeden önce CV Generator konumlandırma ve gereksiz dosya temizliği için plan yazıldı.

### Lesson 5: Secrets Never Become Project Artifacts
- **Hata**: Operasyonel araç bilgileri konuşulurken credential içerebilecek verilerle aynı akışta envanter oluşturma riski doğdu.
- **Kural**: Git, handoff, seed ve testlerde sadece metadata/vault referansı tutulur; ham parola, invite link, cookie veya token asla yazılmaz.
- **Düzeltme**: UI insanlara `Stored in vault` gösterir; agent/API yalnızca `vault://...` referansı dönebilir, ham sır dönemez.

### Lesson 6: Avoid Duplicate Migrations
- **Hata**: `internal_tools` için iki migration oluştu ve test DB'de tablo çakışması yarattı.
- **Kural**: Yeni migration eklemeden önce `rg internal_tools priv/repo/migrations` ile mevcut migration kontrol edilir; duplicate ise silinir veya tek authoritative migration kalır.
- **Düzeltme**: Plan aşamasında duplicate/no-op migration temizliği ayrı madde olarak ele alınacak.
 
### Lesson 7: MCP Tokens Stay Out Of Code
- **Hata Riski**: Windmill MCP gibi token iceren URL'ler konusma icinde paylasildiginda bunlari dogrudan config, handoff, test veya API metadata'sina yazma riski olusur.
- **Kural**: MCP/token URL'leri dosyalarda yalnizca token'siz path olarak tutulur; token konumu `vault_or_env_only` diye anlatilir, ham token asla yazilmaz.
- **Duzeltme**: Windmill entegrasyonu token'siz `mcp_path` ve safe flow catalog ile temsil edilir; gercek token rotasyon + vault/env isidir.
