# Agent2Agent (A2A)

## 1. Genel Bakış
- **Geliştirici:** Google
- **Kategori:** Agent↔Agent İşbirliği (Agent-to-Agent Cooperation)
- **Amaç:** Farklı organizasyonlardaki agent'ların birbirlerini keşfetmesini, müzakere etmesini ve görevleri birbirlerine devretmesini sağlar.

## 2. Mimari ve Çalışma Prensibi
A2A, agent kartları (Agent Cards) ve otonom müzakere protokolü üzerine kuruludur.

### Temel Özellikler:
1. **Agent Kartı (Agent Card):** Bir agent'ın kimliğini, desteklediği standartları, yeteneklerini (skills) ve fiyatlandırma politikasını açıklayan `.well-known/agent-card.json` dosyasıdır.
2. **Görev Devri (Task Delegation):** Bir agent, bütçe ve süre sınırları dahilinde bir görevi başka bir agent'a delege edebilir.
3. **Müzakere (Negotiation):** Agent'lar iş birliği tekliflerini, bütçeyi ve SLA'leri (Service Level Agreement) doğrudan API üzerinden otonom olarak müzakere eder.

## 3. Akış Örneği
```json
{
  "protocol": "A2A",
  "action": "delegate_task",
  "task_id": "task-abc-123",
  "delegated_to": "agent-xyz-987",
  "budget_limit": 5.0,
  "max_steps": 10
}
```
