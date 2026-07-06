# origingame-deploy

Agent skill for deploying AI-made web games (HTML / three.js / Godot HTML5 export) to an [OriginGame](https://github.com/fran0220) server. The agent gets a playable URL, portal page, auto PWA, and optional leaderboard / cloud saves / multiplayer rooms via the auto-injected OG SDK.

## Install

One-liner (auto-detects Claude Code / Factory Droid and installs or updates in place):

```bash
curl -fsSL https://raw.githubusercontent.com/fran0220/origingame-skill/main/install.sh | bash
```

Target a specific tool or directory:

```bash
curl -fsSL .../install.sh | bash -s -- --claude     # ~/.claude/skills
curl -fsSL .../install.sh | bash -s -- --droid      # ~/.factory/skills
curl -fsSL .../install.sh | bash -s -- --project    # ./.claude/skills (project-level)
curl -fsSL .../install.sh | bash -s -- --dir <path> # any skills directory
```

Manual install (any tool supporting the Agent Skills format, i.e. a directory containing `SKILL.md`):

```bash
git clone https://github.com/fran0220/origingame-skill.git ~/.claude/skills/origingame-deploy
```

## Update

Re-run the install one-liner, or:

```bash
git -C ~/.claude/skills/origingame-deploy pull
```

## Requirements

- `OG_HOST` - the OriginGame portal origin
- `OG_DEPLOY_KEY` - deploy key issued by the platform admin (`ogk_...`)

See [SKILL.md](SKILL.md) for the full usage the agent follows.

## Contents

```
SKILL.md            skill instructions (deploy API, OG SDK reference)
scripts/deploy.sh   deploy helper script
install.sh          installer (curl | bash)
```
