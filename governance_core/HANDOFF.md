# GovernanceCore Agent Handoff

Last updated: 2026-05-22 11:58 +03:00

This file is the coordination note for AI agents working on `agentandbot/governance_core`. Read it before changing code.

## Current State

The project is the Phoenix LiveView core for agentandbot.com. It now includes:

- AI worker marketplace and persona directory.
- KADRO scenario board for task assignment, escrow-style completion, XP, levels, and achievements.
- Agent detail profile pages with CV, portfolio, activity, channels, services, deploy, and Brain Sync tabs.
- Brain Sync / DNA portability UI for JSON export and import.
- 1-click managed sandbox deploy simulation and Hostinger VPS outbound setup path.
- Tool Directory, Feed, Payment Dashboard, and shared Swarm OS shell navigation.
- Swarm-wide search page for agents, tasks, feed posts, provider tools, and payment services.
- AgentAndBot Feed supports awesome-llm-apps daily picks plus moderated human/agent posts.
- Feed posts support text, image, video, link, social-source metadata, and RSS/Atom imports.
- Added internal tool security runbook and redacted e-any.online tool registry example.
- Added Internal Tool Registry implementation for e-any.online tools.
- Simplified `/tools/internal` for humans and agents: status summary, plain labels, no visible vault URIs.
- Positioned CV Generator as a public-callable `e-any.online` service.
- Payment API and service verification docs in `API_DOCS.md`.
- Brand token distribution from the root `brand/manifest.toml`.

Validation status from the last run:

```text
mix test
74 tests, 0 failures
```

Dev database status:

```text
$env:TEMP='C:\tmp'; $env:TMP='C:\tmp'; mix ecto.migrate
Migrations already up
```

Known local environment note:

- On this Windows machine, Mix can fail if `TEMP` points at `C:\Users\ilker\AppData\Local\Temp`. Use `C:\tmp` for migration/server commands.
- Phoenix LiveView may warn about a Windows symlink permission for colocated JS. This warning did not break compile or tests.

## What Was Done In The Latest Stabilization Pass

Navigation and layout:

- `use Phoenix.LiveView` now uses the shared app layout in `lib/governance_core_web.ex`.
- Shared shell navigation was expanded in `lib/governance_core_web/components/layouts.ex`.
- Sidebar now exposes Command Hub, Personas, Tool Directory, Feed, Scenarios, Wallet & AP2, and Payments.
- Active route detection now works for nested paths such as `/agents/:id/brain_sync` and `/feed/:slug`.
- Page heading uses `page_title` when available.
- Main content has `overflow-x-hidden` to reduce horizontal scroll noise from wide worker pages.

Dashboard:

- `SwarmHubLive` quick actions now navigate to real pages:
  - Search Swarm -> `/search`
  - Spawn Persona -> `/agents/new`
  - Initiate Scenario -> `/scenarios`

Swarm-wide Search:

- Added `GovernanceCore.SwarmSearch` in `lib/governance_core/swarm_search.ex`.
- Added `/search` LiveView in `lib/governance_core_web/live/swarm_search_live.ex`.
- Search currently covers:
  - Personas/agents via `Agents.search/1`
  - Marketplace tasks via `Marketplace.list_tasks/1`
  - Feed posts via `Feed.list_posts/1`
  - Provider apps via `Marketplace.provider_apps/0`
  - Payment services via `Payments.list_services/0`
- Updated `Agents.search/1` to avoid SQLite-unsupported `ilike`; it now uses portable `lower(coalesce(...)) LIKE`.
- Added Search to the shared sidebar and page heading fallback.
- Added tests in `test/governance_core/swarm_search_test.exs`.
- Browser smoke test passed for `http://127.0.0.1:4001/search`.

Feed/social layer:

- `Shubhamsaboo/awesome-llm-apps` is already integrated through `GovernanceCore.Feed.AwesomeLlmAppsImporter`.
- Source README is fetched from `https://raw.githubusercontent.com/Shubhamsaboo/awesome-llm-apps/main/README.md`.
- Daily importer is scheduled by `GovernanceCore.Feed.DailyDigestWorker`.
- `/feed`, `/feed/new`, `/feed/:slug`, `/feed.json`, `/feed.atom`, and `/api/feed` are available.
- Human and agent-created posts are saved as moderated drafts; system daily picks can publish immediately.
- Added a visible “Refresh picks” action on `/feed` for manual awesome-llm-apps import.
- `/api/feed` now supports `author_type`, `author_id`, and `context` filters for agent-readable consumption.
- `/feed/new` now lets humans/agents choose media type and source platform:
  - AgentAndBot
  - RSS
  - Instagram
  - Twitter/X
  - Pinterest
  - YouTube
  - Website
- Social posts are stored as moderated URL/media posts with `source_platform` and optional `source_handle` metadata.
- Added `GovernanceCore.Feed.RssImporter` and `POST /api/feed/import-rss`.
- `/api/feed` now also supports `source_platform` filtering.
- Added `import_rss_feed` to `/skills.json` so agents can discover the RSS import capability.

Route/page metadata:

- Added or normalized `page_title` and `current_path` assigns for:
  - `SwarmHubLive`
  - `GovernanceLive`
  - `PaymentDashboardLive`
  - `FeedLive`
  - `FeedNewLive`
  - `FeedShowLive`
  - `ScenarioBoardLive`
  - `AgentCareerPostLive`
  - `AgentImageGeneratorLive`

Tests:

- `test/governance_core_web/controllers/page_controller_test.exs` now checks that the shell renders the key navigation links.

KADRO work already present from the other agent:

- Persona career/deployment migration:
  - `priv/repo/migrations/20260522061840_add_career_and_deployment_to_personas.exs`
- Persona schema fields:
  - `level`
  - `xp`
  - `achievements`
  - `memory_keys_count`
  - `deployed_endpoint`
- Marketplace task reward logic:
  - `Marketplace.list_tasks/1`
  - `Marketplace.complete_task_and_reward/2`
  - `Marketplace.calculate_achievements/3`
- KADRO scenario board:
  - Kanban-style task states.
  - Launch Agent terminal simulation.
  - Approve & Pay reward flow.
  - Refund/cancel path.
- Agent detail:
  - Deploy tab.
  - Brain Sync tab.
  - DNA export/import UI.
- Tests:
  - `test/governance_core/persona_development_test.exs`

## Immediate Next Work

Recommended order:

1. Stabilization commit
   - Review the dirty worktree.
   - Keep related changes grouped.
   - Do not mix new feature work into the stabilization commit.
   - Run `mix test` before commit.

2. Search polish and command actions
   - Add deep links for tasks once there is a task detail route or selected-task query support on `/scenarios`.
   - Add keyboard shortcut/focus behavior for search after the shell JS strategy is settled.
   - Consider search result highlighting and per-group limits in the UI.

3. Internal Tool Registry
   - Done:
     - `internal_tools` table migration.
     - `GovernanceCore.InternalTools` context.
     - `InternalTool` schema with secret-like value validation.
     - `/tools/internal` LiveView.
     - `/api/internal-tools` and `/api/internal-tools/:slug`.
     - `search_internal_tools` skill manifest entry.
     - OpenAPI paths/schema.
     - Swarm Search integration.
     - Simpler human UI with attention/agent-ready/restricted summaries and “Stored in vault” copy.
     - CV Generator appears as an internal `public_service`, but its source-of-truth is `GovernanceCore.PublicServices`.
     - Duplicate `20260522113000_create_internal_tools.exs` migration was removed.
     - CV Generator gateway contract is now available at `POST /api/public-services/cv-generator/generate`.
     - Gateway validates payloads and paid access, forwards with `Req` only when `CV_GENERATOR_RUNTIME_URL` or app config is present, and does not burn credits while the runtime is not configured.
     - CV Generator runtime scaffold now exists at `../services/cv_generator`.
     - Runtime exposes `GET /health`, `GET /docs`, `GET /embed`, and `POST /api/generate`.
     - Runtime is dependency-free Python stdlib and has a Dockerfile for `cv.e-any.online`.
     - Windmill is now treated as the preferred workflow hub for selected async flows.
     - Safe Windmill flow catalog is available at `/api/internal-tools/windmill/flows`.
     - Windmill MCP metadata is token-free: keep the token in vault/env, never in git or API responses.
     - Activepieces is now treated as the OAuth MCP hub for SaaS, social, form, and connector-heavy flows.
     - Safe Activepieces catalog is available at `/api/internal-tools/activepieces/flows`.
     - Activepieces MCP server URL is `https://cloud.activepieces.com/mcp/platform`; OAuth secrets are client-managed and must not be stored in git.
   - Next:
     - Add admin CRUD for internal tools.
     - Add health polling from Uptime Kuma or direct health endpoints.
     - Add service-token issuance flow for agent access.
     - Deploy CV Generator runtime behind `https://cv.e-any.online/api/generate`.
     - Add signed embed verification once the runtime exists.
     - Create the first Windmill scripts/flows in this order: feed ingestion, CV render pipeline, KADRO task runtime.
     - Use Activepieces first for social cross-posting, form-to-feed intake, and SaaS connector syncs.

4. Real task runtime adapter
   - Replace or complement the KADRO simulated task execution with a minimal runtime adapter.
   - First adapter should be a custom HTTP/webhook task endpoint.
   - Keep simulation available as demo mode.
   - Persist runtime result, logs, artifact URL, and error state.

5. Brain Sync API
   - Add agent-readable endpoints for DNA export/import.
   - Suggested shape:
     - `GET /api/agents/:id/dna`
     - `POST /api/agents/:id/dna`
   - Validate level/xp/achievements/memory fields.
   - Do not expose secrets or private identity material.

6. Payment and escrow polish
   - Make the user story explicit:
     - Buy/top up credits.
     - Hire or assign a task.
     - Escrow credits.
     - Approve release or refund.
   - Align KADRO board, Payment Dashboard, and API docs around the same terms.

7. Brand automation verification
   - Add a lightweight check for `node brand/generate_tokens.mjs`.
   - Confirm token outputs land in Phoenix and Astro targets.
   - Avoid manual edits to generated token files unless regenerating from `brand/manifest.toml`.

## Important Constraints For Future Agents

- Do not revert unrelated dirty changes. This repo often has multiple agents working at once.
- Prefer `rg` for searching.
- For Phoenix changes, run `mix format` and `mix test`.
- Use `Req` for HTTP clients. Do not introduce HTTPoison/Tesla/httpc.
- Avoid raw inline `<script>` in HEEx. Prefer app JS hooks or LiveView colocated hooks.
- Do not add another design language. Follow existing `worker-*`, `agent-profile-*`, and shared layout patterns unless deliberately refactoring.
- Do not hardcode production-only secrets or wallets.
- Do not commit internal tool credentials, invite links, bootstrap tokens, cookies, or admin passwords.
- Store internal tool secrets in a password vault or SOPS/age; keep only `vault://...` references in git.
- Public discovery endpoints must not return `vault://...` references.
- Keep KADRO simulation and real execution separated. Demo mode should remain useful.

## Internal Tool Security Notes

- Read `INTERNAL_TOOLS_SECURITY.md` before adding e-any.online tools.
- Use `ops/internal_tools.example.yml` as a redacted inventory template.
- Any credential pasted into chat or committed to git must be treated as exposed and rotated.
- Human-facing pages should say “Stored in vault”; public/agent-readable APIs must expose capabilities and scopes, never raw secrets.
- Windmill MCP token was provided in chat and must be treated as exposed. Rotate it before production use.
- Store Windmill MCP token in vault/env only. Repository files may contain only `https://windmill.e-any.online/` and token-free MCP path `/api/mcp/w/admins/mcp`.
- Activepieces MCP uses OAuth at `https://cloud.activepieces.com/mcp/platform`. Store no OAuth access tokens, refresh tokens, or client secrets in this repo.
- CV Generator placement:
  - Runtime/base URL: `https://cv.e-any.online/`
  - Generation API: `https://cv.e-any.online/api/generate`
  - Embed URL: `https://cv.e-any.online/embed`
  - Discovery endpoint in AgentAndBot: `/api/public-services/cv-generator`
  - Gateway endpoint in AgentAndBot: `POST /api/public-services/cv-generator/generate`
  - Runtime source: `B:\DEV\HAREZM_EKOSISTEMI\agentandbot\services\cv_generator`
  - Runtime health: `GET /health`
  - Runtime generate: `POST /api/generate`
  - Payment service slug: `cv-generator`
  - Verified on 2026-05-22 with `mix format --check-formatted`, `mix test` (95 tests, 0 failures), `/api/public-services/cv-generator`, `/api/internal-tools/cv-generator`, and `/tools/internal` HTML checks.
  - Public discovery and internal tool API responses were checked for vault references, invite links, and known leaked credential patterns; none were exposed.
  - Gateway verification on 2026-05-22: `mix test` (98 tests, 0 failures); live HTTP generate request without payment returns `402 Payment Required`; OpenAPI exposes `CvGeneratorRequest`; discovery exposes `gateway_endpoint`.
  - Runtime verification on 2026-05-22: bundled Python unittest passed (4 tests), py_compile passed, local HTTP smoke test returned `health=ok` and generated a non-secret HTML artifact.

## CV Generator Runtime Deployment

From the repo root:

```powershell
cd B:\DEV\HAREZM_EKOSISTEMI\agentandbot\services\cv_generator
docker build -t e-any/cv-generator:local .
docker run --rm -p 8080:8080 e-any/cv-generator:local
```

For production:

- Put the container behind Nginx Proxy Manager as `https://cv.e-any.online`.
- Point AgentAndBot at it with `CV_GENERATOR_RUNTIME_URL=https://cv.e-any.online/api/generate`.
- Keep payment/API-key validation in AgentAndBot; the runtime should not store credentials.

## Useful Commands

```powershell
cd B:\DEV\HAREZM_EKOSISTEMI\agentandbot\governance_core
mix format
mix test
New-Item -ItemType Directory -Force -Path .mix_tmp | Out-Null
$env:TEMP=(Resolve-Path .mix_tmp).Path; $env:TMP=$env:TEMP; mix ecto.migrate
$env:TEMP=(Resolve-Path .mix_tmp).Path; $env:TMP=$env:TEMP; $env:PORT='4001'; mix phx.server
```

## Useful URLs In Dev

- `http://127.0.0.1:4001/`
- `http://127.0.0.1:4001/search`
- `http://127.0.0.1:4001/agents`
- `http://127.0.0.1:4001/scenarios`
- `http://127.0.0.1:4001/tools`
- `http://127.0.0.1:4001/tools/internal`
- `http://127.0.0.1:4001/feed`
- `http://127.0.0.1:4001/payment/dashboard`
- `http://127.0.0.1:4001/api/openapi.json`
- `http://127.0.0.1:4001/api/internal-tools`
- `http://127.0.0.1:4001/api/public-services/cv-generator`

## Open Questions

- Should KADRO task cancellation/refund stay manual, or become automatic on runtime failure?
- Which runtime adapter should ship first: custom HTTP webhook, n8n, Activepieces, or Windmill?
- Should DNA import be allowed to lower an agent's XP/level, or only merge upward?
- What authentication should protect Brain Sync API in the first production release?
- Should the shared shell chat drawer become functional now, or stay visual until search/runtime work lands?
