---
name: using-origingame-assets
description: Finds, previews, and pulls OriginGame's production CC0 game assets (Poly Haven HDRIs/PBR materials/models, Kenney, KayKit, Quaternius, and icons) when they match a game's approved art direction. Prefer the remote asset MCP; a REST helper (assets.sh) is available as a fallback.
---

# Using OriginGame Assets

Use the built-in CC0 asset library for assets whose silhouette, material response, detail density,
scale, and semantic role fit the approved art direction. The curated production corpus includes
self-hosted HDR environments, complete web PBR material bundles, and web-ready glTF/GLB models in
addition to broad game packs. Pull assets into the project and reference them by relative path;
never hotlink asset API URLs from a deployed game.

## Preferred: the asset MCP

Connect an MCP-capable agent to the remote HTTP MCP and authenticate with an OriginGame `sk-` key:

```
endpoint: https://asset-mcp.origingame.dev/mcp
header:   Authorization: Bearer sk-...
```

Tools:

- `assets_search` — query + facets (`resource_type`, `material_type`, `time_of_day`, `weather`, `kind`, `theme`, `visual_style`, `role`, `format`, `game_genre`, `source`). Returns each logical asset's primary and tags.
- `assets_show` — full detail for a group: variant files, formats, target paths, download-only flags.
- `assets_bundle` — a **fetch-plan (no zip)**: direct per-file URLs + target paths under `assets/origingame/`, plus attribution and a manifest. Download each file to its `targetPath` (glTF primary + its `.bin`/textures are included as resources).
- `assets_recommend` — role-bucketed picks (characters / enemies / props / environment / tiles / ui / audio) for a short game brief.
- `assets_facets` — the available facets and values for building filters.

Anonymous browsing (search / show / static thumbnails) is allowed; downloads, glTF resources, and the
interactive 3D viewer require an `sk-` key. Create one at `$OG_HOST/dashboard`. Never print or commit it.

## Fallback: assets.sh (REST)

When MCP is unavailable, use the bundled helper:

```bash
../origingame-deploy/scripts/assets.sh search "weathered medieval knight" --kind 3d --format glb
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

- Start from the project's approved Asset Bill of Materials when one exists. It
  identifies only this game's required roles, art-direction compatibility, source
  strategy, and runtime consumers; it is not a quantity template or approval gate.
- Prefer one cohesive material/silhouette/detail language per scene. The catalog's
  canonical production asset is the selection; do not choose source tiers,
  resolutions, polygon classes, or prospective optimization variants.
- Pull only the groups/files the game actually uses.
- Preserve `ATTRIBUTION.txt` in the project, even though CC0 attribution is optional.
- Install groups, not isolated files: a PBR material needs its map siblings and glTF needs its `.bin`/texture resources. The bundle fetch-plan preserves those runtime relationships; catalog previews remain browse evidence rather than project payload. In og-engine projects, load every texture with an explicit semantic (`color`/`emissive` = sRGB; `normal`/`arm`/`height`/`opacity`/`data` = linear), consume packed ARM once through `game.assets.pbrMaterial()`, and keep sampled terrain choices in the project terrain config rather than project-local shader rewrites.
- A catalog HDRI or the engine neutral light rig is not a default final look. Select environment, time/weather, materials, and light composition for the approved game, or explicitly author a procedural/unlit alternative.
- Catalog availability does not make an asset final. Reject mismatched low-poly,
  preview, or generic kit content rather than weakening an identity-bearing role.

## Asset production order (with Studio / agents)

1. **Read the bill and define the world kit** — name the required terrain, structural, prop, dressing, and actor roles plus their shared silhouette/material/detail language.
2. **Inspect, then accept or reject catalog families** — use search/show/bundle for reusable physical components when a cohesive family meets that bar; do not let catalog availability redefine the art direction.
3. **Generate identity-bearing gaps** — in Studio use its provider-neutral image, 3D, and audio Workbench tools for characters/creatures, hero props, signature architecture, key VFX/UI art, music, and semantic SFX when catalog content would weaken the game. Keep every result local. Outside Studio, use the platform capability documented by the active host rather than embedding a provider call in game code.
4. **Use matching catalog support and dressing** around the primary kit, and author or use procedural treatment only for bill entries assigned that strategy.
5. **Use procedural geometry for systems** such as particles, tiny fillers, and collision helpers—not as a substitute for authored visible forms.

Resolve every applicable bill entry to a local runtime consumer or to an explicit
authored absence such as a procedural sky/unlit treatment. Preview defaults never
count. Start with the canonical production asset and make no multi-resolution or
source-tier decision. Optimize a project-local result only after completed
representative active play exposes a measured bottleneck. Every installed or generated file must
be loaded by the game (relative path). Download URLs expire; never hotlink Gateway
or asset API URLs from a deployed game.
