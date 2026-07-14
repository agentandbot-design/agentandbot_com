# TODO — agentandbot.com

## Dual Flow Architecture ✅ (2026-02-22)

### Completed
- [x] Create implementation plan
- [x] Create Agent Detail LiveView (`/agents/:id`)
- [x] Create Agent Create LiveView (`/agents/new`)
- [x] Create Dashboard LiveView (`/dashboard`)
- [x] Create API: `AgentController` (`/api/agents`)
- [x] Create API: `TaskController` (`/api/tasks`)
- [x] Update router (12 routes)
- [x] Update shared nav (Dashboard link)
- [x] Update agent discovery (ABL.ONE/1.0)
- [x] Add CSS (~600 lines)
- [x] Update Screen Registry (design skill)
- [x] `mix compile` — passed ✅

### Outstanding
- [x] DRY refactor: extract shared agent data to `GovernanceCore.Agents` context module
- [x] Run test suite via `mix test` (95/95 passing)
- [x] Browser verification of all pages
- [x] Update Screen Registry / Stitch schemas
- [x] Update `README.md` to include all recent portal integration details

### Review
- **Compilation**: Clean, zero errors
- **Design Compliance**: All styles use Design System v1 tokens
- **Architecture**: Dual Flow (Human + Machine) fully routed
- **Gap**: Agent data duplicated in 3 files — needs DRY refactor

## CV Generator Public Service Placement — Plan (2026-05-22)

### Goal
Position `CV_GENERATOR` as a simple, secure, public-callable service under `e-any.online`, callable from AgentAndBot, agents, and external websites without leaking credentials or overcomplicating the platform.

### Plan
- [x] Inspect current CV Generator, Internal Tools, Payment Service, OpenAPI, Skill Manifest, route, migration, seed, and test changes.
- [x] Resolve duplicate/temporary artifacts:
  - [x] Delete `20260522113000_create_internal_tools.exs` duplicate migration.
  - [x] Keep `PublicServices` as the CV Generator source-of-truth; InternalTools derives the ops entry from it.
  - [x] Keep only files that serve one clear purpose.
- [x] Define the clean service model:
  - [x] Internal tool entry: operational ownership, health, vault reference, agent scopes.
  - [x] Payment/public service entry: public slug, endpoint, pricing, external-call metadata.
  - [x] Public discovery endpoint: no vault refs, no secrets, embed/API/docs URLs only.
- [x] Confirm URLs and naming:
  - [x] Canonical base: `https://cv.e-any.online/`.
  - [x] API endpoint: `https://cv.e-any.online/api/generate`.
  - [x] Embed endpoint: `https://cv.e-any.online/embed`.
- [x] Implement minimal cleanup after approval:
  - [x] Adjust code paths and tests.
  - [x] Update `HANDOFF.md`.
  - [x] No new CV-specific security rule needed beyond existing vault/no-secret rules.
- [ ] Verify:
  - [x] `mix format --check-formatted`
  - [x] `mix test`
  - [x] HTTP check: `/api/public-services/cv-generator`
  - [x] HTTP check: `/api/internal-tools/cv-generator`
  - [x] UI/HTML check: `/tools/internal` shows CV Generator and `Stored in vault`; Browser plugin check was attempted but the local plugin asset path failed, so the page was verified through HTTP-rendered HTML.
  - [x] Secret scan for known leaked strings and `invite/` patterns in changed files.

### Review
- Implemented and verified.
- Explorer subagent completed and its recommendations were applied: single CV source-of-truth, duplicate migration deletion, API docs secret cleanup, default/persisted registry merge.
- CV Generator is now positioned as the public-callable service at `https://cv.e-any.online/`, with `https://cv.e-any.online/api/generate` and `https://cv.e-any.online/embed` published through `/api/public-services/cv-generator`.
- Internal Tools lists CV Generator as a planned `public_service` operational entry, but public/agent-readable APIs do not expose `secrets_ref`, `vault://` references, invite links, or raw credentials.
- Verification results on 2026-05-22:
  - `mix format --check-formatted`: passed.
  - `mix test`: 95 tests, 0 failures.
  - `/api/public-services/cv-generator`: HTTP 200; no vault or invite strings.
  - `/api/internal-tools/cv-generator`: HTTP 200; no `secrets_ref`, vault, or invite strings.
  - `/tools/internal`: HTTP-rendered UI includes CV Generator and `Stored in vault`; no vault URI, invite string, or known leaked credential patterns.
  - Secret scan found only intentional negative test assertions and a fake example invite URL in tests; no real leaked secrets in the checked project files.
- Operational note: `mix phx.server` failed when `TEMP/TMP` pointed at `C:\tmp` due permission denial. Use a workspace temp directory such as `governance_core/.mix_tmp` when starting Phoenix on this machine.

## CV Generator Gateway Contract — Plan (2026-05-22)

### Goal
Add the smallest real runtime-facing contract for `CV_GENERATOR`: external websites and agents can call AgentAndBot with an API key, AgentAndBot validates credits, and the request is either forwarded to the configured CV runtime or returns a clean operational error while the runtime is not yet deployed.

### Plan
- [x] Add `GovernanceCore.PublicServices.CvGeneratorGateway` with:
  - [x] request payload validation for profile/template/export fields.
  - [x] payment subscription lookup and one-credit deduction only after successful runtime generation.
  - [x] runtime forwarding through `Req` when a runtime base URL is configured.
  - [x] no raw secrets in errors/loggable responses.
- [x] Add API route/controller action:
  - [x] `POST /api/public-services/cv-generator/generate`.
  - [x] Accept `X-API-Key` or `X-Wallet`.
  - [x] Return `402` for missing/insufficient credits.
  - [x] Return `503 runtime_not_configured` until the external service is live.
- [x] Update public discovery/OpenAPI/skill manifest so agents know the generate endpoint exists.
- [x] Add focused tests for:
  - [x] missing payment credentials.
  - [x] insufficient credits.
  - [x] valid paid access does not burn credit while runtime is not configured.
  - [x] metadata/docs include the generate endpoint.
- [x] Verify:
  - [x] `mix format --check-formatted`
  - [x] `mix test`
  - [x] HTTP check for generate endpoint returning expected non-secret error.

### Review
- Implemented and verified.
- Added `GovernanceCore.PublicServices.CvGeneratorGateway` as the runtime-facing contract. It validates CV payloads, authorizes by `X-API-Key` or `X-Wallet`, checks remaining credits, forwards through `Req` only when `CV_GENERATOR_RUNTIME_URL` or app config is present, and deducts one credit only after a successful runtime response.
- Added `POST /api/public-services/cv-generator/generate`.
- Added `gateway_endpoint` to the CV Generator discovery card.
- Updated OpenAPI with `/api/public-services/cv-generator/generate` and `CvGeneratorRequest`.
- Added `generate_cv` to the skill manifest for agent-readable use.
- Verification results:
  - `mix format`: passed.
  - `mix format --check-formatted`: passed.
  - `mix test`: 98 tests, 0 failures.
  - Live HTTP `POST /api/public-services/cv-generator/generate` without payment credentials returns `402 Payment Required`.
  - Live discovery/OpenAPI checks confirm the gateway endpoint and schema are published.
  - Secret scan found only intentional vault references and negative test guards; no raw credential pattern was added.

## CV Generator Runtime Service — Plan (2026-05-22)

### Goal
Create a small deployable runtime service for `cv.e-any.online` so the AgentAndBot gateway has a real target. Keep it simple, Docker-ready, dependency-light, and safe for external sites.

### Plan
- [x] Add `services/cv_generator/` runtime scaffold:
  - [x] Python stdlib HTTP app with no external runtime dependency.
  - [x] `GET /health` for uptime/proxy checks.
  - [x] `GET /docs` for human/agent integration hints.
  - [x] `GET /embed` for iframe/embed smoke tests.
  - [x] `POST /api/generate` for JSON CV generation requests.
- [x] Add deploy artifacts:
  - [x] `Dockerfile`.
  - [x] `.dockerignore`.
  - [x] `README.md` with e-any.online placement and env/run commands.
- [x] Add tests for validation and generation response shape.
- [x] Update ecosystem handoff with deployment instructions.
- [x] Verify:
  - [x] runtime tests.
  - [x] local runtime HTTP smoke test.
  - [x] no secrets in runtime files.

### Review
- Implemented and verified.
- Added `services/cv_generator/app.py`, a dependency-free Python HTTP runtime for `cv.e-any.online`.
- Runtime endpoints:
  - `GET /health`
  - `GET /docs`
  - `GET /embed`
  - `POST /api/generate`
- Added Docker deployment artifacts: `Dockerfile`, `.dockerignore`, and runtime `README.md`.
- Added unittest coverage for payload validation and generated artifact shape.
- Verification results:
  - `python -m unittest discover -s tests`: 4 tests, OK, using bundled Codex Python.
  - `python -m py_compile app.py tests/test_app.py`: passed.
  - Local HTTP smoke test returned `health=ok`, `service=cv-generator`, `generated_status=generated`, `content_type=text/html; charset=utf-8`, and `has_secret=False`.
  - Runtime secret scan returned no credential matches.
- Operational note: PowerShell `Get-Job` hit a local scheduled-jobs permission issue during cleanup inspection, but `Get-NetTCPConnection -LocalPort 8080` showed no listener left behind after the smoke test.

## Windmill Flow Hub Integration — Plan (2026-05-22)

### Goal
Treat Windmill as the preferred internal workflow runner for selected AgentAndBot/e-any.online flows, without committing MCP tokens or admin credentials. Expose a safe flow catalog for humans and agents so future agents know which flows should move to Windmill first.

### Plan
- [x] Update Windmill internal tool metadata:
  - [x] status/health reflect that Windmill is running.
  - [x] add token-free MCP metadata path.
  - [x] keep all MCP/admin tokens in vault/env only.
- [x] Add `GovernanceCore.WindmillFlows` catalog:
  - [x] RSS/social/feed ingestion.
  - [x] CV Generator render pipeline.
  - [x] KADRO task runtime.
  - [x] internal tool health polling.
  - [x] Brain Sync backup/export jobs.
- [x] Add API route `GET /api/internal-tools/windmill/flows` returning safe catalog metadata.
- [x] Update skill manifest/OpenAPI for agent-readable discovery.
- [x] Update handoff and lessons with the no-token MCP rule.
- [x] Verify:
  - [x] `mix format --check-formatted`
  - [x] `mix test`
  - [x] HTTP check for Windmill flow catalog.
  - [x] secret scan confirms the provided MCP token was not written to disk.

### Review
- Implemented and verified.
- Windmill internal tool metadata now reflects `status=active`, `health=running`, and token-free MCP path `/api/mcp/w/admins/mcp`.
- Added `GovernanceCore.WindmillFlows` with 5 recommended workflow candidates: feed ingestion, CV render pipeline, KADRO task runtime, internal tool health polling, and Brain Sync backup.
- Added `GET /api/internal-tools/windmill/flows` for human/agent-readable safe discovery.
- Added `list_windmill_flows` to the skill manifest and OpenAPI schemas for `WindmillFlowCatalog` / `WindmillFlow`.
- Verification results:
  - `mix format`: passed.
  - `mix format --check-formatted`: passed.
  - `mix test`: 99 tests, 0 failures.
  - Live HTTP catalog check returned `slug=windmill`, `mcp_path=/api/mcp/w/admins/mcp`, `flow_count=5`, `has_token=False`.
  - Secret scan confirmed the provided MCP token was not written to checked files; only negative test guards and generic token validation patterns matched.
- Security note: the MCP token shared in chat must be treated as exposed and rotated before production use.

## Activepieces MCP Automation Hub — Plan (2026-05-22)

### Goal
Add Activepieces as a second automation/MCP-compatible hub alongside Windmill. Activepieces uses OAuth via its MCP platform URL, so AgentAndBot should expose only safe server metadata and recommended use cases, not OAuth tokens or user credentials.

### Plan
- [x] Add Activepieces internal tool metadata:
  - [x] public MCP server URL `https://cloud.activepieces.com/mcp/platform`.
  - [x] OAuth auth mode.
  - [x] safe JSON client config example.
- [x] Add `GovernanceCore.ActivepiecesFlows` catalog:
  - [x] social/media cross-posting.
  - [x] SaaS/database/form integrations.
  - [x] human approval flows.
  - [x] public lead/contact automations.
- [x] Add API route `GET /api/internal-tools/activepieces/flows`.
- [x] Update skill manifest/OpenAPI for agent-readable discovery.
- [x] Update handoff with Windmill vs Activepieces division of labor.
- [x] Verify:
  - [x] `mix format --check-formatted`
  - [x] `mix test`
  - [x] HTTP check for Activepieces catalog.
  - [x] secret scan confirms no OAuth token/client secret was written.

### Review
- Implemented and verified.
- Added Activepieces as an OAuth MCP automation hub with public server URL `https://cloud.activepieces.com/mcp/platform`.
- Added `GovernanceCore.ActivepiecesFlows` with 4 recommended flow candidates: social cross-posting, form-to-feed intake, database/form sync, and human approval routing.
- Added `GET /api/internal-tools/activepieces/flows`.
- Added `list_activepieces_flows` to the skill manifest and `ActivepiecesFlowCatalog` to OpenAPI.
- Division of labor:
  - Windmill: internal/long-running jobs, KADRO runtime, CV render jobs, health polling, Brain Sync backups.
  - Activepieces: OAuth/SaaS connector flows, social publishing, form intake, approval routing.
- Verification results:
  - `mix format`: passed.
  - `mix format --check-formatted`: passed.
  - `mix test`: 100 tests, 0 failures.
  - Live HTTP Activepieces catalog check returned `flow_count=4`, `auth_mode=oauth`, `has_secret=False`.
  - Live skills check confirms both `list_activepieces_flows` and `list_windmill_flows`.
  - Secret scan found only negative test guards and a fake example invite URL; no OAuth token/client secret was written.
