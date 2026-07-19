---
name: developing-origingame-games
description: Builds and iterates OriginGame-compatible web games using HTML canvas, three.js, or Godot Web exports. Use when creating or modifying a playable game before deployment.
---

# Developing OriginGame Games

Create or edit games that deploy cleanly to OriginGame and can use the auto-injected `window.OG` SDK for player identity, leaderboard, cloud saves, and rooms.

## Start with the target runtime

- **Plain HTML/canvas**: best for fast arcade prototypes and self-contained games.
- **three.js/Vite**: build first and deploy `dist/`, not the source project.
- **Godot Web**: export for Web and ensure the exported entry file is named `index.html`.

If the official helper is installed, scaffold a dependency-free starter:

```bash
../origingame-deploy/scripts/scaffold-game.sh ./my-game --title "My Game"
python3 -m http.server 8080 -d ./my-game
```

## Development rules

1. Keep `index.html` at the deploy directory root.
2. Use relative asset paths (`./assets/player.png`), never root-absolute paths (`/assets/player.png`).
3. Choose one approved world-kit language before sourcing assets. Use a cohesive CC0 catalog family only when its silhouette, materials, detail, scale, and role coverage fit; otherwise generate the missing terrain, structures, props, and actors through Gateway 3D (`using-origingame-gateway` `/meshy/*` or Studio `origin_workbench_generate_3d`) and use matching catalog support/dressing. Avoid pure procedural hero silhouettes. Never hotlink `/api/assets/...` or expiring generation URLs from a deployed game.
4. Keep the game playable without OriginGame by guarding SDK calls:

```js
const og = window.OG ?? null
og?.ready().catch(console.warn)
```

5. Prefer mobile-safe controls: keyboard plus pointer/touch, responsive canvas, no required right-click or hover-only input.
6. Keep game-state JSON small; cloud saves are capped at 256KB per player.

## OG SDK patterns

Leaderboard:

```js
await window.OG?.leaderboard.submit(score)
const board = await window.OG?.leaderboard.top(10)
```

Cloud save:

```js
await window.OG?.save.set({ level, inventory, bestScore })
const data = await window.OG?.save.get()
```

Rooms use a host-authoritative relay. The host simulates and broadcasts state; guests send inputs:

```js
const room = await window.OG.room.create({ maxPlayers: 4 })
// or: const room = await window.OG.room.join(code)
room.on('message', (data, from) => {})
room.on('hostchange', hostId => {})
room.send({ type: 'input', keys })
room.isHost()
```

Keep room messages under 8KB and under roughly 30 messages/sec/client.

## Pre-deploy check

Run the helper when available:

```bash
../origingame-deploy/scripts/dev-check.sh <game-dir>
```

Manual checklist:

- `index.html` exists at root.
- Assets resolve locally from a static server, not just from the filesystem.
- No `node_modules`, `.git`, source maps, or raw design files in the deploy output.
- The game calls `window.OG?.ready()` once after loading if it uses OriginGame features.
- The game still runs when `window.OG` is absent.

## Hand off to deploy

When the game is playable, use the `origingame-deploy` skill or helper:

```bash
../origingame-deploy/scripts/deploy.sh <game-dir> --title "My Game" --engine html
```

Always report both the returned `playUrl` and `portalUrl`.
