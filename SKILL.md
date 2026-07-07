---
name: origingame-deploy
description: Deploy AI-made web games (HTML / three.js / Godot HTML5 export) to an OriginGame server and get a playable URL. Use when the user asks to publish, deploy, or share a web game they built. Also covers the OG SDK for leaderboards, cloud saves, and multiplayer rooms.
---

# OriginGame Deploy

Deploy a finished web game to an OriginGame server. Players get an instant-play URL, a portal page with likes/comments, an auto-generated PWA (installable, offline-capable), and optional leaderboard / cloud save / multiplayer.

## Prerequisites

Environment variables (ask the user if missing):
- `OG_HOST` - portal origin, e.g. `https://origingame.example.com` (dev: `http://localhost:8787`)
- `OG_API_KEY` - platform API key (`sk-...`)

No key yet? Tell the user to register a free account at `$OG_HOST/login`, then create a key in the dashboard at `$OG_HOST/dashboard`. The same key covers deploys and other platform features (e.g. asset generation).

## Kenney asset library

Before generating new art from scratch, search the built-in Kenney CC0 asset library. Download assets into the game project and reference them with relative paths; never hotlink `/api/assets/...` URLs from a deployed game.

```bash
# Search by natural language + facets
scripts/assets.sh search "pixel platformer player and grass tiles" --kind 2d --format png --limit 8
scripts/assets.sh search "low poly racing car road barrier" --kind 3d --format glb

# Inspect a result group, then download one file or the whole group into the project
scripts/assets.sh show <group-id>
scripts/assets.sh get <file-id> --out ./assets/kenney
scripts/assets.sh bundle --group <group-id> --out ./assets/kenney
```

`search` can run without a key if the server allows public browsing. `get` and `bundle` may require `OG_API_KEY` (`sk-...`). The helper writes `asset-manifest.json` and `kenney-license.txt` next to downloaded files.
Bundle ZIP paths are relative to `--out`; for the default `./assets/kenney`, use paths like `./assets/kenney/2D assets/...` in the game.

## Before deploying, check the game directory

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
