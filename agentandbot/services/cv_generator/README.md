# CV Generator Runtime

Deployable runtime for `https://cv.e-any.online`.

This service is intentionally small: it uses Python's standard library, exposes a stable HTTP contract, and lets AgentAndBot's gateway handle subscriptions, credits, and API keys.

## Endpoints

- `GET /health`: uptime/proxy health check.
- `GET /docs`: JSON integration hints.
- `GET /embed`: iframe/embed smoke-test page.
- `POST /api/generate`: generate a portable CV artifact.

Example request:

```json
{
  "profile": {
    "name": "Ada Lovelace",
    "headline": "AI worker orchestration specialist",
    "summary": "Builds careful automation systems.",
    "experience": ["Designed agent workflows"],
    "skills": ["Python", "Governance"]
  },
  "template": "modern",
  "locale": "tr-TR",
  "export_format": "html"
}
```

The v1 runtime returns a portable HTML artifact for all formats. PDF and DOCX binary renderers can be attached later without changing the AgentAndBot gateway contract.

## Local Run

```powershell
cd B:\DEV\HAREZM_EKOSISTEMI\agentandbot\services\cv_generator
$env:PORT='8080'
python app.py
```

Smoke test:

```powershell
Invoke-WebRequest -UseBasicParsing -Uri 'http://127.0.0.1:8080/health'
```

## Docker

```powershell
docker build -t e-any/cv-generator:local .
docker run --rm -p 8080:8080 e-any/cv-generator:local
```

Production placement:

- Public host: `https://cv.e-any.online`
- Runtime generate URL for AgentAndBot: `CV_GENERATOR_RUNTIME_URL=https://cv.e-any.online/api/generate`
- Nginx Proxy Manager should route `cv.e-any.online` to this container.

## Security Boundary

- Do not put API keys or customer secrets in this service repo.
- AgentAndBot gateway owns payment validation and credit deduction.
- This runtime should only receive the minimum CV profile payload needed to render the artifact.
- Keep generated CV storage optional; v1 returns the artifact inline.
