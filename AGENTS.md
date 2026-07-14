# DOX framework - agentandbot

- DOX is a highly performant AGENTS.md hierarchy installed here.
- Agent must follow DOX instructions across any edits.

## Core Contract

- AGENTS.md files are binding work contracts for their subtrees.
- Work products, source materials, instructions, records, assets, and durable docs must stay understandable from the nearest applicable AGENTS.md plus every parent AGENTS.md above it.

## Read Before Editing

- 🔴 **Software Engineering Principles**: Geliştirmeye başlamadan önce mutlaka [ENTERPRISE-ENGINEERING-PRINCIPLES.md](file:///B:/DEV/ENTERPRISE-ENGINEERING-PRINCIPLES.md) dosyasını okuyun, projenin tier seviyesini belirleyin ve kurallara uyun. Eğer bu kurallar dışında bir uygulama yapılacaksa bu durum `AGENTS.md` dosyasında belirtilmelidir; gerekirse `ENTERPRISE-ENGINEERING-PRINCIPLES.md` dosyası proje klasörüne kopyalanıp özelleştirilmiş bir versiyonu oluşturulabilir. Değişiklik küçükse sadece `AGENTS.md` dosyasında belirtilmesi yeterlidir.
1. Read the root [AGENTS.md](file:///B:/DEV/HAREZM_EKOSISTEMI/AGENTS.md)
2. Identify every file or folder you expect to touch
3. Walk from the repository root to each target path
4. Read every AGENTS.md found along each route
5. If a parent AGENTS.md lists a child AGENTS.md whose scope contains the path, read that child and continue from there
6. Use the nearest AGENTS.md as the local contract and parent docs for repo-wide rules
7. If docs conflict, the closer doc controls local work details, but no child doc may weaken DOX

Do not rely on memory. Re-read the applicable DOX chain in the current session before editing.

## Update After Editing

Every meaningful change requires a DOX pass before the task is done.
Update the closest owning AGENTS.md when a change affects:
- purpose, scope, ownership, or responsibilities
- durable structure, contracts, workflows, or operating rules
- required inputs, outputs, permissions, constraints, side effects, or artifacts
- user preferences about behavior, communication, process, organization, or quality
- AGENTS.md creation, deletion, move, rename, or index contents

Update parent docs when parent-level structure, ownership, workflow, or child index changes. Update child docs when parent changes alter local rules. Remove stale or contradictory text immediately. Small edits that do not change behavior or contracts do not require DOX updates.

## Local Details

- **Role**: LesTupid AI workspace and compatibility layer.
- **Surface**: No direct public domain
- **Type**: workspace
- **Audience**: AI apps, KADRO, adapters
- **Technology**: Markdown, JSON, Elixir/Phoenix and Python sub-services
- **GitHub**: [`https://github.com/ilkerkaanipcioglu/agentandbot`](`https://github.com/ilkerkaanipcioglu/agentandbot`)

## Workspace Index

Below is the directory mapping for this subtree:

- **[agentandbot_com](file:///B:/DEV/HAREZM_EKOSISTEMI/agentandbot/agentandbot_com/AGENTS.md)**: AgentAndBot umbrella for agent services and protocols.
- **[ai_beraberproje](file:///B:/DEV/HAREZM_EKOSISTEMI/agentandbot/ai_beraberproje/AGENTS.md)**: Collective scenario, story, prompt, and video generation workspace.
- **[ai_kadro](file:///B:/DEV/HAREZM_EKOSISTEMI/agentandbot/ai_kadro/AGENTS.md)**: KADRO worker personas, roster, character assets, and platform area.
- **[hermes-integration-spec.md](file:///B:/DEV/HAREZM_EKOSISTEMI/agentandbot/hermes-integration-spec.md)**: Specifications for Hermes AI Agent integration protocols (ACP, A2A, MCP, etc.).
- **[hermes_acp_client.py](file:///B:/DEV/HAREZM_EKOSISTEMI/agentandbot/hermes_acp_client.py)**: Python client for communicating with Hermes over TCP JSON (ACP).
- **[hermes_rest_client.py](file:///B:/DEV/HAREZM_EKOSISTEMI/agentandbot/hermes_rest_client.py)**: Python client for communicating with Hermes REST API Gateway on Port 9877.
- **[telegram_client.py](file:///B:/DEV/HAREZM_EKOSISTEMI/agentandbot/telegram_client.py)**: Telethon-based MTProto client for sending and listening to Telegram messages.
