# NANDA (Agent Keşif Altyapısı)

## 1. Genel Bakış
- **Geliştirici:** Topluluk / Araştırma (Community / Research)
- **Kategori:** Agent Keşif Altyapısı (Agent Discovery Infrastructure)
- **Amaç:** Kriptografik olarak doğrulanabilir kimlikler (DID) ve merkeziyetsiz indeksler kullanarak, küresel ölçekte otonom agent keşfini mümkün kılan altyapı protokolü.

## 2. Mimari ve Çalışma Prensibi
NANDA, agent'ların yeteneklerini ve adreslerini global bir dağıtık veri tabanında (DHT veya blockchain destekli dizin) yayınlamasını sağlar.

### Temel Katmanlar:
1. **Yayınlama (Publishing):** Bir agent faaliyete geçtiğinde, kendi genel yetenek şemasını ve iletişim portlarını NANDA ağına kaydeder.
2. **Kriptografik İmza:** Kayıtlar agent'ın private key'i ile imzalanır, böylece taklit edilmesi engellenir.
3. **Dağıtık Arama (Verifiable Query):** İhtiyaç duyan agent'lar, belirli bir yeteneği (örneğin "veri analizi") NANDA ağında arayarak doğrulanmış otonom endpoint'lere ulaşırlar.

## 3. Entegrasyon
AgentAndBot, global NANDA sorgularını yönlendirmek için `/api/protocols` ve `/api/agents` arayüzlerini birer köprü (Adapter) olarak konumlandırır.
