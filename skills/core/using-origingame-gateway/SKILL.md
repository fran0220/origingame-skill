---
name: using-origingame-gateway
description: Uses OriginGame's Gateway proxy for account API keys, quota-aware OpenAI-compatible model calls, and dashboard self-service. Use when a game or agent needs /gw/v1 AI calls or gateway API-key validation.
---

# Using OriginGame Gateway

OriginGame does not implement accounts, quota, billing, or API-key issuance in this repo. Those live in the separate Origin Gateway service. This app proxies the Gateway at `/gw/api/*` and `/gw/v1/*`.

## Environment

- `OG_HOST`: OriginGame portal origin, e.g. `https://origingame.dev` or `http://localhost:8787`.
- `OG_API_KEY`: Gateway API key (`sk-...`) from `$OG_HOST/dashboard`.
- `OG_MODEL`: optional default model for helper scripts.

Never log, commit, or display `OG_API_KEY`. If credentials need validation, call `/gw/v1/models` and report only success/failure and non-secret response metadata.

## Smoke test

Use the helper when installed:

```bash
../origingame-deploy/scripts/gateway.sh models
../origingame-deploy/scripts/gateway.sh chat "Return one sentence about OriginGame." --model claude-sonnet-4-6
```

Raw equivalent:

```bash
curl -fsS "$OG_HOST/gw/v1/models" \
  -H "Authorization: Bearer $OG_API_KEY"
```

## OpenAI-compatible model calls

Call `/gw/v1/...` through the OriginGame portal origin, not the Gateway origin directly:

```bash
curl -fsS "$OG_HOST/gw/v1/chat/completions" \
  -H "Authorization: Bearer $OG_API_KEY" \
  -H 'Content-Type: application/json' \
  --data '{
    "model": "claude-sonnet-4-6",
    "messages": [{"role":"user","content":"Design a 60-second arcade loop."}]
  }'
```

Use the OpenAI-compatible client shape in app/server code too; set `baseURL` to `$OG_HOST/gw/v1` and pass the Gateway key as the bearer token.

## Browser dashboard APIs

The public dashboard uses `/gw/api/*` with Gateway session cookies and `New-Api-User`. Agent-side scripts should prefer `OG_API_KEY` plus `/gw/v1/*`; do not replay user cookies unless specifically debugging dashboard behavior in a browser session.

## Local development

For local dev, the Node app defaults `GATEWAY_ORIGIN` to `http://localhost:3300`. Build/run the isolated Gateway binary there; do not copy Gateway source into this repository.

```bash
PORT=3300 ./server/data/gateway-dev/gateway
OG_HOST=http://localhost:8787 OG_API_KEY=sk-... ../origingame-deploy/scripts/gateway.sh models
```

## Red lines

- Do not add a parallel `/api/ai` surface to OriginGame unless the Gateway contract changes.
- Do not implement accounts/quota/billing in this repo.
- Do not store raw `sk-` keys server-side; the server hashes deploy-owner keys.
