# Internal Tools Security Runbook

This runbook covers the e-any.online internal services used by Harezm employees, platform services, and agents.

## Immediate Incident Rule

If a password, invite URL, token, cookie, private IP admin URL, or admin username is pasted into chat, committed to git, or shared outside the vault, treat it as exposed.

Do this immediately:

1. Rotate the affected password/token.
2. Revoke invite links and bootstrap tokens.
3. Check recent login/session history in the affected tool.
4. Disable default credentials.
5. Move the new credential into the password vault only.

## What Goes In Git

Git may contain:

- Tool name.
- Public/internal URL.
- Container name.
- Category.
- Owner/team.
- Intended human audience.
- Whether agents may access it.
- Health URL if it does not leak credentials.
- Vault reference such as `vault://e-any/windmill/admin`.
- Required scopes such as `workflow:run`.

Git must never contain:

- Passwords.
- API keys.
- Invite links.
- Session cookies.
- Recovery codes.
- Database connection strings with credentials.
- Admin bootstrap tokens.
- Private SSH keys.

## Recommended Storage

Use one of these as the source of truth for secrets:

- 1Password or Bitwarden for human logins.
- SOPS with age keys for deploy-time secrets.
- Docker secrets or environment variables for containers.
- Per-agent service tokens with narrow scopes for automation.

Keep only redacted references in this repo. See `ops/internal_tools.example.yml`.

## Access Model

Use three levels:

- `human_admin`: full admin access for owners only.
- `human_user`: ordinary employee access.
- `agent_service`: scoped API access, no UI admin login.

Agents should not use shared admin passwords. Give each agent a named service token with:

- Expiry.
- Scope.
- Rate limit.
- Audit label.
- Revocation path.

## Network Policy

Recommended exposure:

- Public internet: only user-facing apps behind HTTPS.
- VPN or allowlist: admin tools such as Portainer, Nginx Proxy Manager, Netdata, database admin.
- Internal Docker network only: Redis, Postgres, Ollama unless explicitly proxied.

Every public subdomain should have:

- HTTPS.
- Strong unique password or SSO.
- No default credentials.
- Uptime check.
- Backup/restore note.

## Baseline Rotation Checklist

Rotate first:

- Nginx Proxy Manager admin.
- Portainer admin.
- Paperclip bootstrap/invite.
- Open WebUI admin.
- Agent Zero admin.
- Space Agent admin.
- Windmill admin.
- SiYuan access password.
- Postgres superuser password.
- Redis password if enabled, or keep Redis private-network only.

Then:

- Create named users.
- Disable shared accounts where possible.
- Add service accounts for agents.
- Store all credentials in the vault.
- Update `ops/internal_tools.example.yml` only with vault references, never the secrets.

## Registry Standard

Each internal tool should be registered with:

```yaml
slug: windmill
name: Windmill
url: https://windmill.e-any.online/
container: windmill-server
category: workflow_automation
audience: [internal_team, agents]
agent_access: true
status: active
auth_mode: sso_or_service_token
health: healthy
data_classification: internal
allowed_agent_scopes: [workflow:run, job:read]
secrets_ref: vault://e-any/windmill/admin
```

## Next Platform Step

Implement an `internal_tools` table and expose:

- `GET /internal-tools`
- `GET /api/internal-tools`
- `GET /api/internal-tools/:slug`

The API must return metadata and scopes, not credentials.
