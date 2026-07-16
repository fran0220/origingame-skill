---
name: using-origingame-assets
description: Finds, previews, and pulls OriginGame's CC0 game assets (Kenney, KayKit, Quaternius, icons) for a game. Prefer the remote asset MCP; a REST helper (assets.sh) is available as a fallback. Use when a game needs sprites, tiles, UI/icons, audio, or 3D models.
---

# Using OriginGame Assets

Use the built-in CC0 asset library before generating new art. Every 3D model exposes a web-ready
glTF/GLB primary; some formats (e.g. FBX) are download-only. Pull assets into the project and
reference them by relative path; never hotlink asset API URLs from a deployed game.

## Preferred: the asset MCP

Connect an MCP-capable agent to the remote HTTP MCP and authenticate with an OriginGame `sk-` key:

```
endpoint: https://asset-mcp.origingame.dev/mcp
header:   Authorization: Bearer sk-...
```

Tools:

- `assets_search` — query + facets (`kind`, `theme`, `visual_style`, `role`, `format`, `game_genre`, `poly_budget`, `source`). Returns each model's web-ready primary (glTF/GLB) and tags.
- `assets_show` — full detail for a group: variant files, formats, target paths, download-only flags.
- `assets_bundle` — a **fetch-plan (no zip)**: direct per-file URLs + target paths under `assets/origingame/`, plus attribution and a manifest. Download each file to its `targetPath` (glTF primary + its `.bin`/textures are included as resources).
- `assets_recommend` — role-bucketed picks (characters / enemies / props / environment / tiles / ui / audio) for a short game brief.
- `assets_facets` — the available facets and values for building filters.

Anonymous browsing (search / show / static thumbnails) is allowed; downloads, glTF resources, and the
interactive 3D viewer require an `sk-` key. Create one at `$OG_HOST/dashboard`. Never print or commit it.

## Fallback: assets.sh (REST)

When MCP is unavailable, use the bundled helper:

```bash
../origingame-deploy/scripts/assets.sh search "low poly medieval knight" --kind 3d --format glb
../origingame-deploy/scripts/assets.sh show <group-id>
../origingame-deploy/scripts/assets.sh bundle --group <group-id> --format glb --out ./assets/origingame
```

`bundle` consumes the same fetch-plan and writes files under `--out` (default `./assets/origingame`)
plus `ATTRIBUTION.txt`. `search`/`show` work without a key; `bundle`/`get` may require `OG_API_KEY` (`sk-...`).

## Deploy attribution

`deploy.sh` auto-detects `asset-manifest.json` under `assets/` and sends the used asset group ids as
`assets_used`. If assets live elsewhere, pass them explicitly:

```bash
../origingame-deploy/scripts/deploy.sh ./dist --title "My Game" --assets "groupid1,groupid2"
```

## Selection guidance

- Prefer one cohesive pack or visual style per scene; keep `poly_budget` consistent for 3D.
- Pull only the groups/files the game actually uses.
- Preserve `ATTRIBUTION.txt` in the project, even though CC0 attribution is optional.

## AAA order of operations (with Studio / agents)

1. **Catalog first** — search/install kit surfaces (environment, props, tiles, enemies, pickups).
2. **Generate 3D only for heroes** the catalog misses after a real search (`origin_workbench_generate_3d` in Studio; Gateway `/meshy/*` for CLI agents). Prefer concept image → image-to-3d.
3. **Generate 2D/audio** for textures, UI, SFX, music as needed.
4. **Procedural geometry** only for particles, tiny fillers, collision helpers — not hero silhouettes.

Every installed or generated file must be loaded by the game (relative path). Download URLs expire; never hotlink Gateway or asset API URLs from a deployed game.
