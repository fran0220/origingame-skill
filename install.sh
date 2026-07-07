#!/usr/bin/env bash
# Installs the origingame-deploy skill into your agent tool's skills directory.
# usage:
#   curl -fsSL https://raw.githubusercontent.com/fran0220/origingame-skill/main/install.sh | bash
#   ... | bash -s -- --claude          # only Claude Code (~/.claude/skills)
#   ... | bash -s -- --codex           # only Codex CLI (~/.codex/skills)
#   ... | bash -s -- --pi              # only Pi (~/.pi/skills)
#   ... | bash -s -- --cursor          # only Cursor (~/.cursor/skills)
#   ... | bash -s -- --droid           # only Factory Droid (~/.factory/skills)
#   ... | bash -s -- --project         # current project (.claude/skills)
#   ... | bash -s -- --dir <path>      # custom skills directory
set -euo pipefail

REPO="https://github.com/fran0220/origingame-skill.git"
NAME="origingame-deploy"

targets=()
case "${1:-auto}" in
  --claude) targets=("$HOME/.claude/skills") ;;
  --codex) targets=("$HOME/.codex/skills") ;;
  --pi) targets=("$HOME/.pi/skills") ;;
  --cursor) targets=("$HOME/.cursor/skills") ;;
  --droid|--factory) targets=("$HOME/.factory/skills") ;;
  --project) targets=("$PWD/.claude/skills") ;;
  --dir) targets=("${2:?usage: --dir <path>}") ;;
  auto)
    [ -d "$HOME/.claude" ] && targets+=("$HOME/.claude/skills")
    [ -d "$HOME/.codex" ] && targets+=("$HOME/.codex/skills")
    [ -d "$HOME/.pi" ] && targets+=("$HOME/.pi/skills")
    [ -d "$HOME/.cursor" ] && targets+=("$HOME/.cursor/skills")
    [ -d "$HOME/.factory" ] && targets+=("$HOME/.factory/skills")
    ;;
  *) echo "unknown option: $1 (use --claude | --codex | --pi | --cursor | --droid | --project | --dir <path>)" >&2; exit 1 ;;
esac

if [ ${#targets[@]} -eq 0 ]; then
  echo "no agent tool detected (~/.claude, ~/.codex, ~/.pi, ~/.cursor or ~/.factory not found)." >&2
  echo "pick a target explicitly: --claude | --codex | --pi | --cursor | --droid | --project | --dir <path>" >&2
  exit 1
fi

command -v git >/dev/null || { echo "git is required" >&2; exit 1; }

for t in "${targets[@]}"; do
  dest="$t/$NAME"
  if [ -d "$dest/.git" ]; then
    git -C "$dest" pull --ff-only --quiet
    echo "updated   $dest"
  elif [ -e "$dest" ]; then
    echo "skipped   $dest (exists but is not a git checkout)" >&2
  else
    mkdir -p "$t"
    git clone --depth 1 --quiet "$REPO" "$dest"
    echo "installed $dest"
  fi
done

echo "done. the skill activates automatically when you ask your agent to deploy a game."
