# AG-UI (Agent-User Interaction)

## 1. Genel Bakış
- **Geliştirici:** CopilotKit
- **Kategori:** Agent↔Kullanıcı Arayüzü (Agent-User Interaction)
- **Amaç:** Agent'lar ile web uygulamalarının arayüzleri (frontend) arasında Server-Sent Events (SSE) tabanlı, çift yönlü gerçek zamanlı veri akışını standartlaştırır.

## 2. Mimari ve Çalışma Prensibi
AG-UI, agent'ın arayüzde dinamik değişiklikler yapmasını (UI bileşenlerini render etme, form alanlarını doldurma vb.) ve kullanıcının eylemlerini anında agent'a aktarmasını sağlar.

### Temel Akış:
1. **Event Akışı (SSE):** Agent, frontend uygulamasına `/api/tasks/{id}/events` üzerinden bir SSE kanalı açar.
2. **Dinamik Render Yeteneği:** Agent, frontende `render_component` eventi göndererek ekranda grafik, harita veya form çizdirebilir.
3. **Kullanıcı Geri Bildirimi:** Kullanıcı arayüzde bir butona tıkladığında frontend, agent'a anlık aksiyon eventi (`user_action`) gönderir.

### Event Örneği:
```json
{
  "event": "render_ui",
  "data": {
    "component": "InteractiveConsentForm",
    "props": {
      "title": "Onay Gerekli",
      "message": "Konum verilerinizin paylaşılmasını onaylıyor musunuz?",
      "action_id": "consent_123"
    }
  }
}
```
