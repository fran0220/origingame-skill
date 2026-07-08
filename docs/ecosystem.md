# OriginGame Skill + Plugin Ecosystem

OriginGame uses a Plannotator-inspired packaging model while preserving the original single-skill deploy install.

## Goals

- Keep `origingame-deploy` backward compatible for existing users and `npm run skill:publish`.
- Add focused core skills for game development, asset discovery, and Gateway usage.
- Keep optional/maintenance workflows under `skills/extra`.
- Treat plugins as thin host adapters over skills and stable helper scripts.

## Published tree

```text
origingame-skill repo root
├── SKILL.md                         # deploy skill, backward compatible
├── README.md
├── install.sh
├── scripts/
│   ├── deploy.sh
│   ├── assets.sh
│   ├── scaffold-game.sh
│   ├── dev-check.sh
│   ├── gateway.sh
│   └── validate-skill-tree.sh
├── skills/
│   ├── core/
│   │   ├── developing-origingame-games/
│   │   ├── using-origingame-assets/
│   │   └── using-origingame-gateway/
│   └── extra/
│       └── maintaining-origingame-skills/
└── plugins/
    └── amp/
        └── origingame.ts
```

## Install modes

- Default: deploy root plus all `skills/core/*`.
- `--deploy-only`: deploy root only, matching the original behavior.
- `--extras`: include `skills/extra/*`.
- `--plugins`: install available host plugin adapters.
- `--all`: core + extras + plugins.

## Safety model

Deploy, Gateway, production, and billing-related actions stay explicit. Skills may instruct an agent to run helper scripts when the user asks, and plugins may append prompts into the current thread, but no plugin should silently deploy or spend Gateway quota.

## Workbench parity map

The lightweight skill line keeps its existing public names for backward compatibility, while the richer `ogkit` workbench line exposes `og-*` skills. Keep this mapping current when changing either tree:

| Workbench skill | Lightweight skill/script |
|---|---|
| `og-develop` | `skills/core/developing-origingame-games` |
| `og-assets` | `skills/core/using-origingame-assets` + `scripts/assets.sh` |
| `og-gateway` | `skills/core/using-origingame-gateway` + `scripts/gateway.sh` |
| `og-check` | `scripts/dev-check.sh` |
| `og-deploy` | root `origingame-deploy` + `scripts/deploy.sh` |
| `og-review` | `ogkit` Plannotator-derived review surface |
| `og-annotate` | `ogkit` Plannotator-derived annotate surface |
| `og-last` | `ogkit` Plannotator-derived last-message annotate surface |

`npm run skill:validate` must stay green after changing the lightweight tree. `ogkit/scripts/install.test.ts` guards the full workbench skill set on the standalone side.

## Adding a skill

1. Choose `skills/core` only for default, broadly useful workflows.
2. Choose `skills/extra` for advanced, maintenance, or high-risk workflows.
3. Create `<skill-name>/SKILL.md` with frontmatter `name` matching the directory.
4. Keep the body compact; put long references in `docs/` or scripts.
5. Run `scripts/validate-skill-tree.sh`.

## Adding a plugin adapter

1. Place host-specific code under `plugins/<host>/`.
2. Keep it a thin adapter over skills/scripts.
3. Add install notes to the plugin README and to the main README if users should install it.
4. Validate it with the host's plugin checker when available.
