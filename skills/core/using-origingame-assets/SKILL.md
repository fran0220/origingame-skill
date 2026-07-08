---
name: using-origingame-assets
description: Searches, inspects, downloads, and attributes OriginGame's built-in Kenney CC0 game asset library. Use when a game needs sprites, tiles, UI art, audio, or 3D models.
---

# Using OriginGame Assets

Use the built-in Kenney CC0 asset library before generating new assets. Download assets into the game project and reference local files with relative paths; never hotlink asset API URLs from a deployed game.

## Search and inspect

Use the helper bundled with `origingame-deploy` when installed:

```bash
../origingame-deploy/scripts/assets.sh search "pixel platformer player and grass tiles" --kind 2d --format png --limit 8
../origingame-deploy/scripts/assets.sh search "low poly racing car road barrier" --kind 3d --format glb
../origingame-deploy/scripts/assets.sh show <group-id>
```

Useful filters include `--kind`, `--theme`, `--visual_style`, `--role`, `--format`, `--game_genre`, `--camera_view`, and `--environment`.

## Download into the project

```bash
../origingame-deploy/scripts/assets.sh get <file-id> --out ./assets/kenney
../origingame-deploy/scripts/assets.sh bundle --group <group-id> --out ./assets/kenney
```

The helper writes:

- `asset-manifest.json` for deploy attribution.
- `kenney-license.txt` with the CC0 license note.

Bundle paths are relative to `--out`. For the default `./assets/kenney`, use paths like:

```html
<img src="./assets/kenney/2D assets/.../player.png" alt="">
```

## Auth behavior

- `search` and `show` can run without a key when the server allows public browsing.
- `get` and `bundle` may require `OG_API_KEY` (`sk-...`). Create one at `$OG_HOST/dashboard`.
- Never print or commit `OG_API_KEY`.

## Deploy attribution

`deploy.sh` auto-detects `asset-manifest.json` under `assets/` and sends the used asset group ids as `assets_used`. If assets live elsewhere, pass them explicitly:

```bash
../origingame-deploy/scripts/deploy.sh ./dist --title "My Game" --assets "groupid1,groupid2"
```

## Selection guidance

- Prefer one cohesive pack or visual style per game scene.
- Keep downloaded bundles small; pull only the groups/files the game actually uses.
- Preserve `kenney-license.txt` in the project, even though CC0 attribution is optional.
