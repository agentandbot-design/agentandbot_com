# Les AI

Les AI, LesTupid ekosisteminin AI/agent uyumluluk ve adapter katmanidir.

AI agent uygulamalarinin ana markasi ve yayin yeri `agentandbot.com`dur.
`agentandbot/` ve ozellikle `agentandbot/governance_core/` bu bagimsiz urunun
runtime alanidir.

LesTupid tarafinda `les_ai`, AgentAndBot uygulamalarinin LesTupid urunleriyle
uyumlu calismasini saglayan sinirdir: certification, identity activation,
portability, optional matchmaking, Les Block proof/value adapter ve app manifest
kurallarini takip eder.

## Guncel Yapi

```text
les_ai/
  agentandbot/
  ai_kadro/
  ai_senaryo/
```

| Klasor | Rol |
| --- | --- |
| `agentandbot/` | AgentAndBot uygulamasi, Governance Core, servisler, blueprint ve agent runtime dosyalari. |
| `ai_kadro/` | KADRO AI worker persona roster, master data ve karakter calisma alani. |
| `ai_senaryo/` | AI ile kolektif senaryo yazma, hikaye ve video uretim notlari. |

## Three AI Layers

- `ai_kadro`: AI agent kadrosu. Bunlar LesTupid'in, bir okulun, bir mekanin,
  bir markanin veya baska bir kullanicinin acikca etiketli AI calisanlari
  olabilir.
- `agentandbot`: genel AI agent platformu. Agent runtime, tool directory,
  governance, marketplace ve task execution burada kalir.
- `ai_senaryo`: AI ile kolektif senaryo, hikaye, film/video fikri ve servis
  simulasyonu uretme alani.

## Runtime Modes

- `standalone_app`: AgentAndBot/Governance Core `agentandbot.com` urunu olarak
  kendi basina calisir.
- `ecosystem_activated_app`: LesTupid urunleri AI review, scenario, agent task,
  evidence summary veya automation adapter'larini aktive ederek kullanir.

AgentAndBot'un yayin ve urun kimligi LesTupid'e bagimli degildir. LesTupid
sadece uyumluluk, aktivasyon ve adapter sozlesmesini tanimlar.

## Agentic Auth

WorkOS `auth.md` modelinden alinan stratejiye gore AgentAndBot, LesTupid
ekosistemindeki agent delegasyonlari icin ana authorization yuzeyidir. KADRO
agentlari bu yuzey uzerinden kesfedilir, ise alinir, scope alir, denetlenir ve
gerekirse iptal edilir.

Ilk faz `contract_only_v1`dir: AgentAndBot ve KADRO auth discovery endpointleri
yayinlar; gercek token minting, claim ceremony ve revocation kayitlari ikinci
faz Phoenix auth context'i ile eklenecektir.

Detay: `../docs/AGENTIC_AUTH_STRATEGY.md`

## LesTupid Alignment

Les AI may help:

- Les Certification: evidence summaries, manipulation checks, review drafts.
- Les Wait: queue feedback summaries, delay explanations, fake check-in signals.
- Les Match: explainable recommendation assistance, safety review summaries.
- Les Match: clearly labeled AgentAndBot/KADRO agent, mentor, worker, or task
  candidate suggestions.
- Les Poke: quest generation support and local discovery summaries.
- Les Commerce: merchant/product review, offer clarity and checkout evidence.
- Les Go: KADRO worker cards, AgentAndBot task launch cards and ai_senaryo
  collective scenario cards.
- ai_senaryo: collective story, prompt, storyboard and render workflows.

AI may not silently issue final certification, activate matchmaking, publish
private user data, or replace app-owned business logic.

KADRO agents may appear in Les Match only as labeled AI agents. They must never
be shown as unlabeled human matches.

## Specs

- `lestupid-ai-integration-spec.md`
- `ai_kadro/LESTUPID_KADRO_POLICY.md`
- `ai_senaryo/collective-scenario-flow.md`
