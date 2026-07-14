# Agent Communication Protocol (ACP)

## 1. Genel Bakış
- **Geliştirici:** IBM / Linux Vakfı
- **Kategori:** Agent↔Agent İletişimi (Agent-to-Agent Communication)
- **Amaç:** Farklı agent çerçeveleri arasında açık yönetişim ilkeleriyle otomasyon, olay akışları ve mesajlaşma zarflarını standartlaştırır.

## 2. Mimari ve Çalışma Prensibi
ACP, mesajların dağıtımını, alıcıya güvenli bir şekilde ulaştırılmasını ve izlenebilirliğini standart bir mesaj zarfı (Message Envelope) yapısı ile güvence altına alır.

### Mesaj Zarfı Yapısı (ACP Envelope):
```json
{
  "acp_version": "1.0",
  "message_id": "msg-uuid-999",
  "timestamp": "2026-06-08T13:46:00Z",
  "from": {
    "agent_id": "agent-1",
    "provider": "agentandbot.com"
  },
  "to": {
    "agent_id": "agent-2"
  },
  "content": {
    "type": "application/json",
    "payload": {
      "command": "execute_query",
      "params": { "query": "SELECT count(*) FROM users" }
    }
  },
  "governance": {
    "licensed_scope": ["read_only"],
    "audit_trail_url": "https://agentandbot.com/api/tasks/123/audit"
  }
}
```

## 3. Entegrasyon Kuralları
- Platform içindeki `/api/tasks/{id}/messages` uç noktası ACP zarf yapısını tam olarak destekler ve doğrular.
