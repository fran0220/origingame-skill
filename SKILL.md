---
name: origingame-deploy
description: Deploy AI-made web games (HTML / three.js / Godot HTML5 export) to an OriginGame server and get a playable URL. Use when the user asks to publish, deploy, or share a web game they built. Also covers the OG SDK for leaderboards, cloud saves, and multiplayer rooms.
---

# OriginGame Deploy

Deploy a finished web game to an OriginGame server. Players get an instant-play URL, a portal page with likes/comments, an auto-generated PWA (installable, offline-capable), and optional leaderboard / cloud save / multiplayer.

## Plugin modules

This deploy skill is the backward-compatible root of the **OriginGame Plugin**. Skills are modules inside the plugin, not the product surface itself. When the task is not strictly deployment, prefer the focused sibling skills installed by `install.sh`:

- `developing-origingame-games` — build or modify HTML/canvas, three.js, or Godot Web games before deployment.
- `using-origingame-assets` — find and pull the built-in CC0 asset library (Kenney/KayKit/Quaternius/icons) via the asset MCP (or the `assets.sh` REST fallback) and attach attribution.
- `using-origingame-gateway` — use `/gw/v1` and Gateway `sk-` keys for quota-aware OpenAI-compatible model calls.
- `maintaining-origingame-skills` — maintain this skill/plugin ecosystem.

Do not silently deploy or spend Gateway quota unless the user explicitly asked for that operation.

## Prerequisites

This file is the **deploy skill** inside the **OriginGame Plugin** (not “the whole product”).  
Install the plugin via Dashboard Setup or `install.sh --claude` / `--codex` / `--pi` / `--cursor`.

Environment variables (ask the user if missing — same contract as Studio / Dashboard):
- `OG_HOST` — portal origin, e.g. `https://origingame.dev` (dev: `http://localhost:8787`)
- `OG_API_KEY` — Gateway API key (`sk-...`)

Legacy aliases still accepted: `ORIGINGAME_SK_KEY` (= API key), `ORIGINGAME_DEPLOY_ORIGIN` / `ORIGINGAME_HOST` (= host). Prefer the `OG_*` names.

No key yet? User must register at `$OG_HOST/login`, then create a key in **`$OG_HOST/dashboard/keys`**.  
Dashboard Setup pastes install + env with the real key; do not invent keys.

## CC0 asset library

Before generating new art from scratch, search the built-in CC0 asset library (Kenney, KayKit,
Quaternius, icon packs). Every 3D model exposes a web-ready glTF/GLB primary. Download assets into the
game project and reference them with relative paths; never hotlink `/api/assets/...` URLs from a game.

Agents should prefer the remote asset MCP (see the `using-origingame-assets` skill):

```
https://asset-mcp.origingame.dev/mcp   (Authorization: Bearer sk-...)
tools: assets_search · assets_show · assets_bundle · assets_recommend · assets_facets
```

REST fallback via the bundled helper (bundles return a fetch-plan, no zip):

```bash
scripts/assets.sh search "weathered medieval knight" --kind 3d --format glb
scripts/assets.sh show <group-id>
scripts/assets.sh bundle --group <group-id> --format glb --out ./assets/origingame
```

`search`/`show` run without a key when public browsing is enabled; `bundle`/`get` may require
`OG_API_KEY` (`sk-...`). The helper writes files under `--out` (default `./assets/origingame`) plus
`ATTRIBUTION.txt`; reference them like `./assets/origingame/kaykit/.../model.gltf` in the game.

## Before deploying, check the game directory

Run the helper if available:

```bash
scripts/dev-check.sh <game-dir>
```

1. `index.html` MUST exist at the directory root.
   - Godot: export for Web, then rename `yourgame.html` to `index.html`.
   - Vite/bundled three.js projects: run the build first and deploy the build output dir (e.g. `dist/`), never the source dir.
2. All asset paths must be relative (`./assets/x.png`, not `/assets/x.png`).
3. Do not include `node_modules`, `.git`, or source maps. The platform strips junk automatically, but a lean zip deploys faster.

## Deploy

Use the bundled helper script if available, otherwise raw curl.

```bash
# script (bundled with this skill)
scripts/deploy.sh <game-dir> --title "My Game" [options]

# raw curl equivalent
cd <game-dir> && zip -qr /tmp/game.zip .
curl -sS -X POST "$OG_HOST/api/deploy" \
  -H "Authorization: Bearer $OG_API_KEY" \
  -F "file=@/tmp/game.zip" \
  -F "title=My Game" \
  -F "engine=threejs" \
  -F "genre=arcade" \
  -F "license_mode=protected" \
  -F "description=One-line pitch" \
  -F "max_players=1" \
  -F "cover=@cover.png"
```

Fields:
| field | values | notes |
|---|---|---|
| `title` | text | required |
| `engine` | `html` / `threejs` / `godot` | default `html` |
| `genre` | `arcade` / `action` / `puzzle` / `shooter` / `platformer` / `racing` / `strategy` / `casual` / `cards` / `other` | gameplay category for the portal Arcade browse tabs; pick the closest one, default `other` |
| `license_mode` | `protected` / `open` | `protected` = no derivatives: JS is auto-minified+obfuscated, no source access. `open` = open source: shows license badge and source link |
| `license_name` | e.g. `MIT` | only for `open` |
| `source_url` | repo URL | only for `open` |
| `description` | text ≤2000 | shown on portal |
| `orientation` | `any` / `landscape` / `portrait` | mobile hint + PWA orientation |
| `aspect` | `16:9`, `9:16`, ... | letterbox ratio; omit for full-window responsive games |
| `max_players` | 1-16 | >1 shows the multiplayer badge |
| `unlisted` | `1` | playable by URL but hidden from portal |
| `cover` | png/jpg ≤2MB | 16:9 recommended; auto-placeholder if omitted |
| `creator` | handle e.g. `nova` | attributes the game to a creator; enables the `/u/<handle>` profile page |
| `creator_name` | display name | optional friendly name for the byline |
| `assets_used` | JSON array | asset group ids used, for portal backlinks; `deploy.sh` auto-detects asset manifests under `assets/` |

`deploy.sh` also accepts `--creator`, `--creator-name`, `--assets` (or `OG_CREATOR` / `OG_CREATOR_NAME` env). When your game dir has an `asset-manifest.json` under `assets/` (written by `assets.sh`), the used assets are attached automatically for portal attribution.

Response: `{ "gameId": "...", "playUrl": "...", "portalUrl": "..." }`. Always report `playUrl` and `portalUrl` to the user.

Update an existing game (new version, same URL):
```bash
curl -sS -X PUT "$OG_HOST/api/deploy/<gameId>" -H "Authorization: Bearer $OG_API_KEY" -F "file=@/tmp/game.zip"
```
Delete: `curl -X DELETE "$OG_HOST/api/deploy/<gameId>" -H "Authorization: Bearer $OG_API_KEY"`
List my games: `GET $OG_HOST/api/deploy/mine`

## OG SDK (auto-injected, zero setup)

The platform injects `window.OG` into every deployed game. Do NOT bundle or import anything. Guard usage so the game still runs standalone during local development:

```js
const og = window.OG ?? null
og?.ready()                                  // call once when the game has loaded
```

**Local mock:** for previews without deploy, optionally load `sdk/dev/og-sdk-dev.js` from the monorepo (attaches a memory leaderboard/save stub). Never ship that file in production deploys.

Leaderboard and cloud save (per-player, JSON up to 256KB):
```js
await og.leaderboard.submit(score)           // -> { ok, rank }
const { top, me } = await og.leaderboard.top(10)
await og.save.set({ level: 3, coins: 120 })
const data = await og.save.get()             // null if none
const name = await og.player.name()
```

Multiplayer rooms (message relay, host-authoritative pattern). Do NOT write your own game server; use rooms:
```js
const room = await og.room.create({ maxPlayers: 4 })  // room.code is a 6-char join code, show it to the player
// or: const room = await og.room.join(code)
room.on('message', (data, from) => { /* apply remote input/state */ })
room.on('peerjoin', id => {})
room.on('peerleave', id => {})
room.on('hostchange', hostId => {})          // host migration: check room.isHost()
room.send({ type: 'state', ... })            // broadcast to others (or room.send(data, peerId))
room.isHost()                                // host runs authoritative simulation, broadcasts state
room.leave()
```
Pattern: the host peer simulates the game and broadcasts state ~10-20 times/sec; guests send inputs to the host. Keep messages ≤8KB, ≤30 msgs/sec per client.

## After deploying

1. Report the play URL and portal URL to the user.
2. Suggest testing on both desktop and mobile.
3. If the game would benefit from a leaderboard, saves, or multiplayer and does not use them yet, offer to add OG SDK calls and redeploy with PUT.
