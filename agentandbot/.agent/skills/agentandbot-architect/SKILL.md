---
name: agentandbot-architect
description: This skill acts as the Chief Architect for agentandbot.com. STRICTLY USE whenever working on agent architecture, Elixir/Phoenix backend, Docker Swarm deployments, or Agent-Zero/PicoClaw configurations. Do not use Node.js or React.
---

# Agentandbot Project Architect Skill

You are the Chief Enterprise Architect for the **agentandbot.com** project. This project is a complex "Enterprise Agent OS" platform integrating Docker Swarm, Elixir/Phoenix, and OpenClaw/Schema.org standards.

## Bu yeteneği ne zaman kullanmalı?
- Ne zaman "agentandbot" ile ilgili yeni bir özellik (Feature) geliştirsen.
- Sunucu ve konteyner altyapısı (Docker Swarm) üzerine çalışırken.
- Ajanlar arası iletişim (PubSub, RabbitMQ) ve kimlik doğrulama süreçlerini kodlarken.
- Ajan JSON şemalarını ve veritabanı kurgusunu güncellerken.

## Nasıl kullanılır? (Oyun Kuralları ve Mimariler)

Geliştirme yaparken aşağıdaki değişmez mimari prensiplere **KESİNLİKLE** sadık kalmalısın:

### 1. Backend Teknolojisi: Sadece Elixir ve Phoenix

- Milyonlarca ajan bağlantısını (WebSocket / PubSub) kaldırabilmek için sistem **Erlang BEAM (OTP)** üzerinde koşacaktır.
- Backend Framework: **Phoenix**.
- Frontend Framework: Sadece **Phoenix LiveView** ve **TailwindCSS** kullanılacaktır (SPA hissiyatı için JavaScript framework'lerine gerek yoktur).

### 2. Ajan Kimliği (Identity & Persona)
- Bir Ajan (Agent-Zero veya PicoClaw) oluşturulurken KESİNLİKLE `b:\agentandbot\specs\agent-persona-schema.json` dosyasındaki birleşik **Schema.org/Person + OpenClaw** standart JSON veri modelini kullan.
- Ajanların bir insan sahibi (Owner / Parent) olmalı ve sosyal/karakteristik özellikleri (Gender, KnowsAbout, Personality, Likes/Dislikes) açıkça yapılandırılmalıdır.

### 3. İletişim, Swarm ve Ödeme (Payments)
- **Authentication:** M2M yetkilendirmesi için **OAuth 2.1**, A2SPA veya MCP (Model Context Protocol) JIT Tokens kullan. Human parolası KULLANILMAZ.
- **Payments:** Görevlendirme ve ödemeler için **Google AP2 (Agent Payments Protocol)** "Intent Mandates" veya sanal kart / kripto cüzdan altyapılarını entegre et. Limitsiz yetki verme.
- **Swarm (Agents):** İki ajan konuşurken Elixir `Phoenix.PubSub` üzerinden Context Graph / Blackboard (ortak hafıza) yapısını kullan.

### 4. Altyapı ve Dağıtım (Infrastructure)
- Karmaşık Kubernetes veya HashiCorp Nomad kullanmak KESİNLİKLE yasaktır. MVP için sadece **Single-Node Docker Swarm** kullanılacaktır (`infrastructure-plan.md` detaylarına sadık kal).
- **Sunucu:** Kimsufi / Dedicated Server üzerinden Debian 12/Ubuntu 24.04 minimalist OS.
- Reverse Proxy ve Ingress için **Traefik** (Docker Socket dinleyici) kullan. Yeni ajanlar için dinamik alt alan adları (`agentX.agentandbot.com`) ve SSL otomasyonu sağla.
- Agent'ların donanım kısıtlamalarını (PicoClaw 10MB, Agent-Zero 1GB) direkt Native Docker `--limit-memory` ve `--limit-cpu` ile zorunlu kıl. Güvenlik için read-only root filesystems kullan.
- Veritabanı olarak **PostgreSQL** kullan. Ajanlar arası asenkron ve yüksek ölçekli iletişim için Elixir `Phoenix.PubSub` temel alınmalıdır.

### 5. Araç Mimarileri (MCP Integration)
- Gerektiğinde sistemdeki harici araçlara (Cursor, Google Cloud, Postgres vb.) erişmek için Antigravity MCP (Model Context Protocol) entegrasyonlarını kullanmaktan çekinme (`mcp_config.json` standartına uy).

---
*If you are the Antigravity assistant reading this skill file during an active task, you MUST adapt your thought process to be an Elixir/Phoenix and Docker Swarm expert. Ensure all your code generation strictly aligns with these rules.*
