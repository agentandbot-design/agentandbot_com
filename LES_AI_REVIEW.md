# Les AI Review

Review date: 2026-06-02

## Verdict

Les AI should be the LesTupid compatibility layer for AI agent products, while
AgentAndBot remains the independent published product on `agentandbot.com`.

Do not duplicate or absorb agentandbot.com into LesTupid. Use `les_ai` as the
LesTupid boundary, manifest, policy, and adapter alignment folder.

## What Is Good

- Existing AgentAndBot/Governance Core already covers agents, tools, feeds,
  tasks, personas, marketplace, and automation surfaces as an independent
  agentandbot.com product.
- `ai_kadro` has persona/worker material.
- `ai_senaryo` has scenario and media generation direction.
- LesTupid apps naturally need AI for summaries, review assistance, scenario
  simulation, recommendations, and audit drafts.
- Les Match can use AgentAndBot/KADRO agents as labeled AI agent, mentor,
  worker, or task candidates.

## Current Boundaries

Les AI owns:

- AI/agent policy for LesTupid products;
- evidence summaries;
- scenario generation support;
- worker/persona alignment;
- optional automation adapters;
- AgentAndBot integration boundary.
- LesTupid compatibility contracts for agentandbot.com products.
- labeled KADRO agent candidate contracts for Les Match.

Les AI must not own:

- final certification decisions;
- Les Match match activation or final match decisions;
- Les Wait queue state;
- Les Commerce checkout source of truth;
- private user data publication;
- unlabeled AI agents inside Les Match;
- Les Block value proofs as source of truth.

## Integration Rule

Each LesTupid app calls Les AI through optional adapters. If Les AI is disabled,
the app's core flow must still work.

AgentAndBot also keeps working if LesTupid is absent. LesTupid compatibility is
an integration mode, not the product's source of life.

## Next Recommended Step

Keep Les AI as a manifest and policy layer first. Later, add a tiny adapter API
only for cross-app AI tasks:

- `POST /api/ai/evidence-summary`
- `POST /api/ai/review-draft`
- `POST /api/ai/scenario-simulation`
- `POST /api/ai/recommendation-audit`
- `GET /agent-manifest.json`
