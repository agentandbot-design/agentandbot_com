# AConP (Agent Connect Protocol)

## 1. Genel Bakış
- **Geliştirici:** Cisco
- **Kategori:** Agent Çağırma Standardı (Agent Invocation Standard)
- **Amaç:** Ajanların ağ üzerinden başlatılması, yürütülmesi, duraklatılması, kaldığı yerden devam ettirilmesi ve çıktıların bir akış (streaming) halinde alınması için standart API arayüzü tanımlar.

## 2. Mimari ve Çalışma Prensibi
AConP, ağ seviyesinde agent oturumlarını (Agent Sessions) yönetir.

### API Metotları ve Durum Yönetimi:
- `connect`: Agent ile bir WebSocket veya gRPC bağlantısı başlatır.
- `execute`: Belirli bir talimat seti ile agent'ı çalıştırır.
- `pause` / `resume`: Uzun süren işlemlerde agent'ın çalışma durumunu dondurur ve geri yükler.
- `stream_outputs`: Agent'ın ürettiği logları ve ara sonuçları anlık olarak istemciye aktarır.

## 3. Entegrasyon
Platformdaki `/agent/connect` LiveView arayüzü ve API katmanı, harici agent'ların bağlantı kurmasını ve AConP standartlarında oturum yönetimi simülasyonunu gerçekleştirir.
