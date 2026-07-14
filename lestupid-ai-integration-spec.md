# LesTupid AI Integration Spec

Les AI is the compatibility layer between LesTupid products and AI systems
published under AgentAndBot, KADRO, and ai_senaryo.

## Product Boundaries

| System | Role | LesTupid usage |
| --- | --- | --- |
| `ai_kadro` | Labeled AI worker and persona roster | Worker suggestions, study help, mentor prep, service support, agent-to-task matching |
| `agentandbot` | Independent AI agent platform | Agent runtime, tool directory, task execution, marketplace, governance |
| `ai_senaryo` | Collective scenario and AI video workspace | Campus stories, service simulations, quest scripts, short film ideas, collaborative creative boards |

AgentAndBot stays independent on `agentandbot.com`. LesTupid apps consume it
through optional adapters and activation cards.

## Core Rule

Static things stay as pages: agents, teams, workspaces, projects, scenarios,
universities, venues, certifications.

Moving things become feed events: task requests, agent suggestions, scenario
drafts, review comments, queue explanations, match prompts, proof events and
render jobs.

## KADRO In LesTupid

KADRO agents are AI workers, employees, mentors, assistants or performers.
They may belong to LesTupid or to external users/organizations.

Allowed use:

- student study worker;
- sponsor/mentor prep agent;
- merchant support worker;
- venue operations helper;
- certification evidence summarizer;
- Les Match labeled AI mentor/worker;
- scenario actor, writer, editor or reviewer.

Required labels:

- source: `les_ai/kadro` or `agentandbot.com`;
- identity type: `ai_agent`, `ai_worker`, `ai_persona`, or `human_operator`;
- owner: LesTupid, external user, organization, or unknown/unverified;
- capability: what the agent is allowed to do;
- consent state: visible before any private data is used.

Forbidden use:

- presenting an AI agent as an unlabeled human;
- silently activating matchmaking;
- importing private messages or location history by default;
- platform evasion, fake account warming, spam, or deceptive bot behavior;
- final certification, final match decision, or final payment decision without
  human/app-owned review.

## AgentAndBot In LesTupid

AgentAndBot provides runtime and governance. LesTupid should launch AgentAndBot
as an external task workspace, not absorb it into one giant LesTupid backend.

Typical LesTupid cards:

- "Ask an agent to prepare my sponsor note";
- "Turn this queue issue into a venue support task";
- "Summarize this certification evidence";
- "Create a study plan from this check-in";
- "Route this creative idea to scenario board".

Each card must say when it opens AgentAndBot and when data leaves the current
LesTupid app.

## ai_senaryo In LesTupid

ai_senaryo is for collective story, film, prompt and video creation. It can also
simulate product flows before engineering work starts.

Use cases:

- school/campus short film and creator challenge;
- event recap script;
- Les Poke quest script;
- Les Wait service simulation;
- Les Match safety scenario;
- adult dating/travel expectation and consent checklist for 18+ contexts;
- Les Commerce product story;
- Les Certification review training scenario.

Contributor rules:

- AI-generated output must be labeled;
- human contributors must be credited or anonymized by consent;
- real students/minors cannot be used as characters without explicit policy;
- adult dating or travel companion scenarios must not present money, gifts,
  access or travel as payment for sexual services;
- generated media should keep prompt, source, model and review metadata.

## Feed Tempo

AI events must follow the LesTupid time model:

- `live`: agent is responding now, queue explanation, active render;
- `short`: quick draft, short study block, limited task window;
- `today`: daily plan, event prep, recap;
- `ongoing`: scenario board, agent task, mentorship workflow;
- `stable`: agent profile, project page, scenario bible, certification policy.

## Adapter Contract

Minimum opportunity shape for LesTupid apps:

```json
{
  "type": "agent_help",
  "source_app": "les_ai/kadro",
  "title": "KADRO study worker",
  "reason": "A labeled AI worker can split this course into a revision plan.",
  "required_activation": "les-ai",
  "safety_labels": ["AI agent labeled", "user controlled"],
  "tempo": "today"
}
```

No adapter may execute private actions automatically in v1. Cards are previews
and explicit launch points.
