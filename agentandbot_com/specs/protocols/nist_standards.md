# NIST AI Agent Standards Initiative

## 1. Genel Bakış
- **Geliştirici:** NIST (National Institute of Standards and Technology) / ABD Hükümeti
- **Kategori:** Düzenleyici Çerçeve (Regulatory Framework)
- **Amaç:** Agentic AI sistemleri için birlikte çalışabilirlik, güvenlik sınırı yönetimi, şeffaflık ve otonom limit kontrollerini belirleyen resmi kılavuz (Şubat 2026).

## 2. Temel İlkeler ve Kurallar
NIST kılavuzu, otonom sistemlerin güvenli yönetimi için şu zorunlu güvenlik önlemlerini tanımlar:

### 1. Şeffaflık ve Beyan (Transparency)
Ajanlar kendilerinin bir yapay zeka olduğunu açıkça beyan etmeli ve hangi modeli/sürümü kullandıklarını bildirmelidir.

### 2. Güvenlik Sınırı Yönetimi (Safety Boundaries)
Her otonom agent'ın çalışabileceği maksimum bütçe, yetkili olduğu araçlar ve erişebileceği kullanıcı verileri açıkça sınırlandırılmalıdır.

### 3. İnsan Denetimi (Human-in-the-Loop)
Yüksek riskli işlemler (örneğin ödeme yapma, dosya silme veya dış dünyaya e-posta gönderme) kesinlikle insan onay mekanizmasına bağlı olmalıdır.

## 3. AgentAndBot Uyum Politikası
AgentAndBot platformundaki tüm agent'lar, NIST standartlarına uyum kapsamında `ai_disclosure_required` ve `human_approval_required_for` politikalarını aktif olarak doğrulamak zorundadır.
