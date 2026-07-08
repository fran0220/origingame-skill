---
name: maintaining-origingame-skills
description: Maintains the OriginGame skill and plugin ecosystem, including core/extra skills, shared helper scripts, Amp plugin adapters, installers, validation, and publishing. Use when changing skill packaging or agent integrations.
---

# Maintaining OriginGame Skills

Use this when editing the published `origingame-skill` ecosystem. The model follows the Plannotator-style split: compact core skills, optional extra workflows, and thin host-specific plugin adapters over stable scripts/APIs.

## Layout contract

```text
skill/origingame-deploy/
  SKILL.md                 # backward-compatible deploy skill and published root
  README.md                # install and ecosystem docs
  install.sh               # cross-agent installer
  scripts/                 # stable helpers used by skills/plugins
  skills/
    core/                  # default install skills
    extra/                 # opt-in advanced/maintenance skills
  plugins/
    amp/                   # Amp command-palette adapter
  docs/                    # design notes and host-adapter guidance
```

Do not move the published root without also changing `npm run skill:publish` and the one-line installer URL. Prefer additive changes that keep existing `origingame-deploy` installs working.

## Skill authoring rules

- Every skill directory contains `SKILL.md` with `name` matching the directory and a concrete `description` trigger.
- Keep each `SKILL.md` focused and under 500 lines; move deep details into `docs/` or helper scripts.
- Core skills are safe defaults: game development, deploy, Gateway, assets.
- Extra skills are opt-in: maintenance, production, release, complex workflows.
- Operational skills must not auto-deploy, mutate production, or spend Gateway quota without an explicit user request.

## Plugin rules

- Plugins are adapters, not sources of truth. They should open URLs, append prompts, or call stable scripts.
- Keep dangerous actions explicit. A command-palette item may ask the active thread to deploy; it should not silently deploy.
- Amp plugin source lives in `plugins/amp/origingame.ts`. Install globally to `~/.config/amp/plugins/origingame.ts` or project-locally to `.amp/plugins/origingame.ts`.

## Installer rules

- Default install should install the deploy root plus `skills/core/*`.
- `--extras` installs `skills/extra/*`.
- `--plugins` installs host adapters such as the Amp plugin.
- `--deploy-only` keeps backward-compatible deploy-root-only behavior.
- Do not delete unrelated user files outside the targeted skill/plugin directories.

## Validation

Run before publishing:

```bash
bash skill/origingame-deploy/scripts/validate-skill-tree.sh skill/origingame-deploy
npm run skill:publish
```

If helper scripts changed, also run `bash -n` on them and a local smoke test with a temp starter game.
