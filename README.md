# OriginGame Skill Ecosystem

Agent skills and thin plugin adapters for building, deploying, and operating AI-made web games on [OriginGame](https://github.com/fran0220/origingame).

The published repository remains backward-compatible with the original `origingame-deploy` skill, but now also includes focused skills for game development, Gateway usage, asset discovery, and skill/plugin maintenance.

## Install

Default install: deploy root + core skills.

```bash
curl -fsSL https://raw.githubusercontent.com/fran0220/origingame-skill/main/install.sh | bash
```

Install modes:

```bash
curl -fsSL https://raw.githubusercontent.com/fran0220/origingame-skill/main/install.sh | bash -s -- --deploy-only # deploy root only, legacy-compatible
curl -fsSL https://raw.githubusercontent.com/fran0220/origingame-skill/main/install.sh | bash -s -- --extras    # include optional extra skills
curl -fsSL https://raw.githubusercontent.com/fran0220/origingame-skill/main/install.sh | bash -s -- --plugins   # include Amp plugin adapter
curl -fsSL https://raw.githubusercontent.com/fran0220/origingame-skill/main/install.sh | bash -s -- --all       # core + extras + plugins
```

Target a specific tool or directory:

```bash
curl -fsSL .../install.sh | bash -s -- --claude      # ~/.claude/skills
curl -fsSL .../install.sh | bash -s -- --codex       # ~/.codex/skills
curl -fsSL .../install.sh | bash -s -- --pi          # ~/.pi/skills
curl -fsSL .../install.sh | bash -s -- --cursor      # ~/.cursor/skills
curl -fsSL .../install.sh | bash -s -- --droid       # ~/.factory/skills
curl -fsSL .../install.sh | bash -s -- --agents      # ~/.config/agents/skills
curl -fsSL .../install.sh | bash -s -- --amp-skills  # ~/.config/amp/skills
curl -fsSL .../install.sh | bash -s -- --project     # ./.claude/skills and ./.amp/plugins when --plugins is set
curl -fsSL .../install.sh | bash -s -- --dir <path>  # any skills directory
```

Manual legacy install (single deploy skill only):

```bash
git clone https://github.com/fran0220/origingame-skill.git ~/.claude/skills/origingame-deploy
```

## Skills

Default/core install:

- `origingame-deploy` — deploy finished HTML / three.js / Godot Web games and use OG SDK reference.
- `developing-origingame-games` — create and iterate playable web games before deployment.
- `using-origingame-assets` — find and pull the built-in CC0 asset library (Kenney/KayKit/Quaternius/icons) via the asset MCP or `assets.sh`, and attach attribution.
- `using-origingame-gateway` — use `/gw/v1` and Gateway `sk-` keys for quota-aware OpenAI-compatible calls.

Optional extra install:

- `maintaining-origingame-skills` — maintain this skill/plugin ecosystem.

See [`docs/ecosystem.md`](docs/ecosystem.md) for the packaging model.

## Helper scripts

```text
scripts/deploy.sh              deploy/update a game directory
scripts/assets.sh              search/show/bundle CC0 assets (fetch-plan; MCP preferred)
scripts/scaffold-game.sh       create a dependency-free canvas starter
scripts/dev-check.sh           validate a game directory before deploy
scripts/gateway.sh             smoke-test /gw/v1 models and chat calls
scripts/validate-skill-tree.sh validate skills, scripts, and plugin layout
```

Common flow:

```bash
scripts/scaffold-game.sh ./my-game --title "My Game"
python3 -m http.server 8080 -d ./my-game
scripts/dev-check.sh ./my-game
scripts/deploy.sh ./my-game --title "My Game" --engine html
```

## Amp plugin

The Amp adapter adds command-palette prompts and dashboard opening. It does not silently deploy or call the Gateway.

Install with the main installer:

```bash
curl -fsSL https://raw.githubusercontent.com/fran0220/origingame-skill/main/install.sh | bash -s -- --plugins
```

Or manually:

```bash
mkdir -p ~/.config/amp/plugins
cp plugins/amp/origingame.ts ~/.config/amp/plugins/origingame.ts
```

Then run `plugins: reload` from Amp's command palette.

## Requirements

- `OG_HOST` — OriginGame portal origin, e.g. `https://origingame.dev` or `http://localhost:8787`.
- `OG_API_KEY` — Gateway API key (`sk-...`), created in `$OG_HOST/dashboard`.

No key yet? Register/login at `$OG_HOST/login`, then create one in the dashboard. The same key covers deploys, asset downloads when auth is required, and `/gw/v1` model calls.

## Publish from the OriginGame monorepo

The source of truth is `skill/origingame-deploy/` in the OriginGame repo. Do not edit the published `origingame-skill` repo directly.

```bash
bash skill/origingame-deploy/scripts/validate-skill-tree.sh skill/origingame-deploy
npm run skill:publish
```
