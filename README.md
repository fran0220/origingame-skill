# origingame-deploy

Agent skill for deploying AI-made web games (HTML / three.js / Godot HTML5 export) to an [OriginGame](https://github.com/fran0220) server. The agent gets a playable URL, portal page, auto PWA, and optional leaderboard / cloud saves / multiplayer rooms via the auto-injected OG SDK.

## Install

Clone this repo into your agent tool's skills directory:

```bash
# Claude Code (personal)
git clone https://github.com/fran0220/origingame-skill.git ~/.claude/skills/origingame-deploy

# Claude Code (project)
git clone https://github.com/fran0220/origingame-skill.git .claude/skills/origingame-deploy

# Factory Droid
git clone https://github.com/fran0220/origingame-skill.git ~/.factory/skills/origingame-deploy
```

Any other tool that supports the Agent Skills format (a directory containing `SKILL.md`) works the same way: clone into its skills directory.

## Update

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
```
