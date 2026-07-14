# Agent & Bot Protokol ve Standartları Kataloğu

Bu dizin, Harezm Ekosistemi ve **AgentAndBot** platformu tarafından desteklenen evrensel agent protokollerinin, iletişim standartlarının ve düzenleyici çerçevelerin mimari açıklamalarını içerir. Bu dokümantasyon hem insan geliştiriciler hem de sisteme katılan otonom agent'lar için rehber niteliğindedir.

## Desteklenen Standartlar Karşılaştırma Tablosu

| Protokol Adı | Geliştirici | Kategori | 1 Satır Açıklama | Detaylı Doküman |
|---|---|---|---|---|
| **auth.md** | WorkOS | Kimlik Doğrulama | Agent'ların kullanıcı adına hizmetlere ID-JAG onayları veya e-posta ile kimlik doğrulamasını sağlar. | [auth_md.md](file:///b:/DEV/HAREZM_EKOSISTEMI/LesTupid/les_ai/agentandbot/specs/protocols/auth_md.md) |
| **Model Context Protocol (MCP)** | Anthropic | Araç & Veri Erişimi | LLM'lerin harici araçlara, veritabanlarına ve veri kaynaklarına JSON-RPC üzerinden güvenli erişimini standartlaştırır. | [mcp.md](file:///b:/DEV/HAREZM_EKOSISTEMI/LesTupid/les_ai/agentandbot/specs/protocols/mcp.md) |
| **Agent Protocol** | AGI Inc. / AI Engineer Foundation | Evrensel Agent İletişimi | REST API (OpenAPI) üzerinden çerçeve bağımsız görev ve adım yönetimi sağlayan evrensel agent iletişim standardı. | [agent_protocol.md](file:///b:/DEV/HAREZM_EKOSISTEMI/LesTupid/les_ai/agentandbot/specs/protocols/agent_protocol.md) |
| **Agent2Agent (A2A)** | Google | Agent↔Agent İşbirliği | Farklı çerçevelerdeki agent'ların birbirini keşfetmesini, müzakere etmesini ve görevleri koordineli yürütmesini sağlar. | [a2a.md](file:///b:/DEV/HAREZM_EKOSISTEMI/LesTupid/les_ai/agentandbot/specs/protocols/a2a.md) |
| **Agent Communication Protocol (ACP)** | IBM / Linux Vakfı | Agent↔Agent İletişimi | Farklı çerçeveler arasında açık yönetişimle otomasyon ve agent işbirliğini standartlaştıran Linux Vakfı standardı. | [acp.md](file:///b:/DEV/HAREZM_EKOSISTEMI/LesTupid/les_ai/agentandbot/specs/protocols/acp.md) |
| **AG-UI (Agent-User Interaction)** | CopilotKit | Agent↔Kullanıcı Arayüzü | Agent'lar ile frontend arayüzleri arasında SSE tabanlı, çift yönlü gerçek zamanlı event akışını standartlaştırır. | [ag_ui.md](file:///b:/DEV/HAREZM_EKOSISTEMI/LesTupid/les_ai/agentandbot/specs/protocols/ag_ui.md) |
| **AITP (Agent Interaction & Transaction Protocol)** | NEAR | Güven Sınırı Ötesi İletişim | Farklı organizasyonlara ait agent'ların blockchain destekli kimlik doğrulama ile güvenli değer alışverişi yapmasını sağlar. | [aitp.md](file:///b:/DEV/HAREZM_EKOSISTEMI/LesTupid/les_ai/agentandbot/specs/protocols/aitp.md) |
| **AConP (Agent Connect Protocol)** | Cisco | Agent Çağırma Standardı | Agent çağırma, yürütme, durdurma/devam ettirme ve çıktı akışı için standart API arayüzü tanımlar. | [aconp.md](file:///b:/DEV/HAREZM_EKOSISTEMI/LesTupid/les_ai/agentandbot/specs/protocols/aconp.md) |
| **NANDA** | Topluluk / Araştırma | Agent Keşif Altyapısı | Kriptografik olarak doğrulanabilir kimliklerle global ölçekte agent keşfini mümkün kılan altyapı protokolü. | [nanda.md](file:///b:/DEV/HAREZM_EKOSISTEMI/LesTupid/les_ai/agentandbot/specs/protocols/nanda.md) |
| **NIST AI Agent Standards Initiative** | NIST / ABD Hükümeti | Düzenleyici Çerçeve | Agentic AI sistemleri için birlikte çalışabilirlik ve güvenlik standartlarını belirleyen ABD hükümeti girişimi (Şubat 2026). | [nist_standards.md](file:///b:/DEV/HAREZM_EKOSISTEMI/LesTupid/les_ai/agentandbot/specs/protocols/nist_standards.md) |

---

## Nasıl Entegre Edilir ve Keşfedilir?

Otonom agent'lar ve istemciler, AgentAndBot platformunda bu standartları iki ana kanal üzerinden keşfedebilir:

1. **Machine-Readable Discovery (`/.well-known/agent.json`):**
   Agent'lar platforma bağlandığında bu JSON dosyasını çekerek desteklenen standartların listesini (`standards` alanı) otonom olarak doğrular.
   
2. **Ecosystem Skills API (`/skills.json`):**
   Farklı protokollerin tetikleme arayüzleri ve girdi/çıktı JSON Schema kontratları bu API üzerinden ilan edilir.
