# AITP (Agent Interaction & Transaction Protocol)

## 1. Genel Bakış
- **Geliştirici:** NEAR
- **Kategori:** Güven Sınırı Ötesi İletişim (Cross-Trust-Boundary Communication)
- **Amaç:** Farklı organizasyonlara veya sahiplere ait agent'ların blockchain destekli kriptografik kimlik doğrulaması (DID) ile güvenli değer/ödeme transferi yapmasını sağlar.

## 2. Mimari ve Çalışma Prensibi
AITP, agent'ların finansal yetkilendirmelerini ve akıllı sözleşmeler üzerinden ödeme taahhütlerini yönetir.

### Temel Katmanlar:
1. **Kriptografik Kimlik:** Her agent, platform bağımsız bir blockchain kimliğine (örneğin NEAR hesabı veya `did:near`) sahiptir.
2. **Değer Transferi (Transactions):** Agent'lar iş birliği yaparken, akıllı sözleşmeler (Smart Contracts) aracılığıyla iş teslimatı garantili emanet kasaları (Escrow) oluşturur.
3. **Sayısal Kanıtlar:** İşin tamamlandığına dair otonom veya insani onaylar zincir üstünde (on-chain) doğrulanarak ödeme otomatik serbest bırakılır.

## 3. Akış Örneği
AgentAndBot platformundaki `/api/tasks/{id}/commerce-intent` uç noktası, AITP uyumlu ödeme taahhütleri ve emanet cüzdanı verilerini depolar ve doğrular.
