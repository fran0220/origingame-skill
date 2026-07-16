---
name: using-origingame-gateway
description: Uses OriginGame's Gateway proxy for account API keys, quota-aware OpenAI-compatible model calls, and dashboard self-service. Use when a game or agent needs /gw/v1 AI calls or gateway API-key validation.
---

# Using OriginGame Gateway

OriginGame does not implement accounts, quota, billing, or API-key issuance in this repo. Those live in the separate **Origin Gateway** service, whose source is the **you-box** repository (`fran0220/you-box`, AGPL). This app only proxies Gateway HTTP at `/gw/api/*` and `/gw/v1/*`.

Architecture authority in the monorepo: `docs/origin-gateway.md` (when working inside OriginGame).

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

## Media generation (image + speech)

The Gateway relays OpenAI-compatible image and text-to-speech. Prefer the CC0 asset
library first; use generation for bespoke art or voiceover. Generation spends quota,
so only run it when the user asked for it.

Image (`gpt-image-2`) — returns `data[0].b64_json` (base64 PNG); decode and save into the project:

```bash
curl -fsS "$OG_HOST/gw/v1/images/generations" \
  -H "Authorization: Bearer $OG_API_KEY" -H 'Content-Type: application/json' \
  --data '{ "model": "gpt-image-2", "prompt": "flat pixel-art coin, transparent background", "n": 1, "size": "1024x1024" }'
```

Image generation often takes 15-60s. Prefer the direct Gateway host for long image
jobs: `https://api.origingame.dev/v1/images/generations` with the same key. Chat and
speech are usually fine via `$OG_HOST/gw/v1`; Studio Maker / Mission LLM streams must
always use `https://api.origingame.dev` (never portal `/gw` for long SSE).

Speech / text-to-speech (`eleven_v3`) — `voice` must be a real ElevenLabs `voice_id`
(generic OpenAI names like `alloy` are rejected); returns raw MP3 bytes:

```bash
curl -fsS "$OG_HOST/gw/v1/audio/speech" \
  -H "Authorization: Bearer $OG_API_KEY" -H 'Content-Type: application/json' \
  --data '{ "model": "eleven_v3", "input": "Welcome, pilot.", "voice": "21m00Tcm4TlvDq8ikWAM", "response_format": "mp3" }' \
  --output ./assets/audio/intro.mp3
```

Sound effects (`eleven_text_to_sound_v2`) — returns raw MP3 bytes:

```bash
curl -fsS "$OG_HOST/gw/v1/sound-generation" \
  -H "Authorization: Bearer $OG_API_KEY" -H 'Content-Type: application/json' \
  --data '{ "text": "Short clean retro arcade coin pickup chime, no voice", "model_id": "eleven_text_to_sound_v2", "duration_seconds": 1.5, "loop": false }' \
  --output ./assets/audio/coin.mp3
```

Music (`music_v2`) — use concise, instrumental game-ready tracks unless the brief
calls for vocals; returns raw MP3 bytes:

```bash
curl -fsS "$OG_HOST/gw/v1/music" \
  -H "Authorization: Bearer $OG_API_KEY" -H 'Content-Type: application/json' \
  --data '{ "prompt": "Energetic retro arcade battle loop, bright chiptune, no vocals", "model_id": "music_v2", "music_length_ms": 30000, "force_instrumental": true }' \
  --output ./assets/audio/battle-theme.mp3
```

## Browser dashboard APIs

The public dashboard uses `/gw/api/*` with Gateway session cookies and `New-Api-User`. Agent-side scripts should prefer `OG_API_KEY` plus `/gw/v1/*`; do not replay user cookies unless specifically debugging dashboard behavior in a browser session.

## Local development

For local dev, the Node app defaults `GATEWAY_ORIGIN` to `http://localhost:3300`. Run Origin Gateway from the **you-box** checkout or a prebuilt image listening on that port (or point `GATEWAY_ORIGIN` at a remote gateway). Do not copy Gateway source into this repository.

```bash
# Example: gateway process on :3300 (from you-box image or binary — not from this tree)
OG_HOST=http://localhost:8787 OG_API_KEY=sk-... ../origingame-deploy/scripts/gateway.sh models
```

Production long-SSE base remains `https://api.origingame.dev` (or `OG_AI_GATEWAY`), not portal `/gw`.

## Red lines

- Do not add a parallel `/api/ai` surface to OriginGame unless the Gateway contract changes.
- Do not implement accounts/quota/billing in this repo.
- Do not vendor you-box / new-api AGPL source into OriginGame.
- Do not store raw `sk-` keys server-side; the server hashes deploy-owner keys.
