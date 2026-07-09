# OriginGame Plugin Ecosystem

**Plugin is the product surface** that agents install (Claude Code / Codex / Pi / Cursor / Amp).  
**Skills** are focused instruction modules *inside* the plugin.  
**Scripts** (`deploy.sh`, `assets.sh`, …) are the stable execution waist.

Do not call the whole package “a skill” in product copy — say **OriginGame Plugin**.

OriginGame uses a packaging model that keeps the original `origingame-deploy` root skill for backward compatibility while shipping a multi-skill plugin tree.

## Goals

- Keep `origingame-deploy` backward compatible for existing users and `npm run skill:publish`.
- Present install UX as **plugin install** (`install.sh --claude` / Dashboard Setup).
- Skills cover develop / assets / gateway / deploy; scripts do the work.
- Host plugins (Amp, etc.) are thin adapters — never silent deploy or silent quota spend.

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

## Product lines (naming)

| Line | What users install | Role |
|---|---|---|
| **OriginGame Plugin** | `install.sh` → agent skills dir | Agent-native create → assets → gateway → deploy |
| **OriginGame Studio** | Desktop Electron app | IDE workbench + publish UI (Settings → OriginGame for sk- / origin) |
| **ogkit** | Advanced workbench (optional) | Review/annotate + `og-*` skills; not the default creator path |

## Env contract (unified)

| Variable | Meaning | Used by |
|---|---|---|
| `OG_API_KEY` | Gateway `sk-…` | Plugin scripts, Dashboard Setup |
| `ORIGINGAME_SK_KEY` | Same key (Studio alias) | Studio main process (also accepts `OG_API_KEY`) |
| `OG_HOST` | Portal origin (deploy + docs links) | Plugin `deploy.sh`, Studio deploy origin |
| `ORIGINGAME_DEPLOY_ORIGIN` | Studio publish origin override | Studio (allowlist: localhost:8787 + `https://*.origingame.dev`) |

Dashboard Setup generates `OG_API_KEY` + `OG_HOST` + `OPENAI_BASE_URL` for agents.  
Studio Settings → OriginGame stores key + allowlisted origin under `~/.origingame-studio/`.

## Workbench parity map

The plugin skill line keeps public skill names for backward compatibility; the richer `ogkit` line exposes `og-*` skills:

| Workbench skill | Plugin skill/script |
|---|---|
| `og-develop` | `skills/core/developing-origingame-games` |
| `og-assets` | `skills/core/using-origingame-assets` + `scripts/assets.sh` |
| `og-gateway` | `skills/core/using-origingame-gateway` + `scripts/gateway.sh` |
| `og-check` | `scripts/dev-check.sh` |
| `og-deploy` | root `origingame-deploy` + `scripts/deploy.sh` |
| `og-review` | `ogkit` review surface |
| `og-annotate` | `ogkit` annotate surface |
| `og-last` | `ogkit` last-message annotate |

`npm run skill:validate` must stay green after changing the plugin tree.

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
