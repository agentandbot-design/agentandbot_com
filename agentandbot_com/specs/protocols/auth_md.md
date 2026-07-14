# auth.md - WorkOS Delegated Authentication Protocol

## 1. Genel Bakış
- **Geliştirici:** WorkOS
- **Kategori:** Kimlik Doğrulama (Identity & Authentication)
- **Amaç:** Agent'ların, kullanıcıların adına yetkilendirilmiş API servislerine ve platform dışı kaynaklara erişimini güvenli hale getirmek.

## 2. Mimari ve Çalışma Prensibi
Agent'lar kullanıcı adına işlem yaparken doğrudan şifre veya uzun vadeli kullanıcı token'larını kullanmazlar. Bunun yerine geçici, kısıtlı yetkili ve geri alınabilir otonom token'lar kullanırlar.

### Kimlik Doğrulama Akışı:
1. **Keşif (Discovery):** Agent `/.well-known/oauth-protected-resource` uç noktasını sorgular.
2. **Yetkilendirme Sunucusu (Authorization Server):** Dönen yanıttaki `authorization_servers` üzerinden `/.well-known/oauth-authorization-server` dosyasına ulaşır ve token endpoint'ini öğrenir.
3. **ID-JAG veya E-posta Kanıtı (Identity Assertion):** Agent, WorkOS entegrasyonu üzerinden kullanıcıya ait bir kimlik onayını (`identity_assertion`) ya da e-posta onay kodunu doğrular.
4. **Kısıtlı Token Temini:** `/oauth2/token` üzerinden geçici JWT token'ını temin eder.

## 3. Güvenlik Kuralları
- Token süreleri (TTL) maksimum 300 saniye olmalıdır.
- Kullanıcı dilediği an agent yetkilendirmesini iptal edebilir (Revocation). İptal tetiklendiğinde WorkOS, ilişkili tüm JWT token'larını anında geçersiz kılar.
- Hassas işlemler (örneğin ödeme onayı veya profil güncelleme) her durumda kullanıcı onayı (MFA veya onay ekranı) gerektirir.
