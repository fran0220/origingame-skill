#!/usr/bin/env bash
# Installs the OriginGame skill ecosystem into agent skill directories.
#
# Default: deploy root + core skills.
# Useful modes:
#   curl -fsSL https://raw.githubusercontent.com/fran0220/origingame-skill/main/install.sh | bash
#   ... | bash -s -- --deploy-only      # deploy root only, legacy-compatible
#   ... | bash -s -- --extras           # also install optional extra skills
#   ... | bash -s -- --plugins          # also install Amp plugin adapter
#   ... | bash -s -- --all              # core + extras + plugins
#   ... | bash -s -- --claude           # ~/.claude/skills
#   ... | bash -s -- --codex            # ~/.codex/skills
#   ... | bash -s -- --pi               # ~/.pi/skills
#   ... | bash -s -- --cursor           # ~/.cursor/skills
#   ... | bash -s -- --droid            # ~/.factory/skills
#   ... | bash -s -- --agents           # ~/.config/agents/skills
#   ... | bash -s -- --amp-skills       # ~/.config/amp/skills
#   ... | bash -s -- --project          # ./.claude/skills and ./.amp/plugins
#   ... | bash -s -- --dir <path>       # custom skills directory
set -euo pipefail

REPO="https://github.com/fran0220/origingame-skill.git"
DEPLOY_NAME="origingame-deploy"

target_mode="auto"
custom_dir=""
install_core=1
install_extras=0
install_plugins=0

usage() {
  cat <<'USAGE'
Installs the OriginGame skill ecosystem into agent skill directories.

Default: deploy root + core skills.
Useful modes:
  install.sh --deploy-only      deploy root only, legacy-compatible
  install.sh --extras           also install optional extra skills
  install.sh --plugins          also install Amp plugin adapter
  install.sh --all              core + extras + plugins
  install.sh --claude           ~/.claude/skills
  install.sh --codex            ~/.codex/skills
  install.sh --pi               ~/.pi/skills
  install.sh --cursor           ~/.cursor/skills
  install.sh --droid            ~/.factory/skills
  install.sh --agents           ~/.config/agents/skills
  install.sh --amp-skills       ~/.config/amp/skills
  install.sh --project          ./.claude/skills and ./.amp/plugins
  install.sh --dir <path>       custom skills directory
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --claude|--codex|--pi|--cursor|--droid|--factory|--agents|--amp-skills|--project)
      target_mode="$1"; shift ;;
    --dir)
      target_mode="--dir"; custom_dir="${2:?usage: --dir <path>}"; shift 2 ;;
    --minimal|--deploy-only)
      install_core=0; install_extras=0; shift ;;
    --extras)
      install_extras=1; shift ;;
    --no-extras)
      install_extras=0; shift ;;
    --plugins)
      install_plugins=1; shift ;;
    --skills-only)
      install_plugins=0; shift ;;
    --all)
      install_core=1; install_extras=1; install_plugins=1; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *) echo "unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

command -v git >/dev/null || { echo "git is required" >&2; exit 1; }
command -v tar >/dev/null || { echo "tar is required" >&2; exit 1; }

targets=()
case "$target_mode" in
  --claude) targets=("$HOME/.claude/skills") ;;
  --codex) targets=("$HOME/.codex/skills") ;;
  --pi) targets=("$HOME/.pi/skills") ;;
  --cursor) targets=("$HOME/.cursor/skills") ;;
  --droid|--factory) targets=("$HOME/.factory/skills") ;;
  --agents) targets=("$HOME/.config/agents/skills") ;;
  --amp-skills) targets=("$HOME/.config/amp/skills") ;;
  --project) targets=("$PWD/.claude/skills") ;;
  --dir) targets=("$custom_dir") ;;
  auto)
    [[ -d "$HOME/.claude" ]] && targets+=("$HOME/.claude/skills")
    [[ -d "$HOME/.codex" ]] && targets+=("$HOME/.codex/skills")
    [[ -d "$HOME/.pi" ]] && targets+=("$HOME/.pi/skills")
    [[ -d "$HOME/.cursor" ]] && targets+=("$HOME/.cursor/skills")
    [[ -d "$HOME/.factory" ]] && targets+=("$HOME/.factory/skills")
    [[ -d "$HOME/.config/agents" ]] && targets+=("$HOME/.config/agents/skills")
    [[ -d "$HOME/.config/amp" ]] && targets+=("$HOME/.config/amp/skills")
    ;;
esac

if [[ ${#targets[@]} -eq 0 ]]; then
  echo "no agent skills directory detected." >&2
  echo "pick a target explicitly: --claude | --codex | --pi | --cursor | --droid | --agents | --amp-skills | --project | --dir <path>" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" 2>/dev/null && pwd || pwd)"
tmp=""
cleanup() { [[ -n "$tmp" ]] && rm -rf "$tmp"; }
trap cleanup EXIT

if [[ -f "$SCRIPT_DIR/SKILL.md" && -d "$SCRIPT_DIR/scripts" ]]; then
  SRC="$SCRIPT_DIR"
else
  tmp="$(mktemp -d)"
  git clone --depth 1 --quiet "$REPO" "$tmp/repo"
  SRC="$tmp/repo"
fi

copy_tree() {
  local src="$1" dest="$2" parent tmpdest
  parent="$(dirname "$dest")"
  tmpdest="$parent/.tmp-$(basename "$dest").$$"
  rm -rf "$tmpdest"
  mkdir -p "$tmpdest" "$parent"
  (cd "$src" && tar --exclude='.git' -cf - .) | (cd "$tmpdest" && tar -xf -)
  rm -rf "$dest"
  mv "$tmpdest" "$dest"
}

install_skill_dir() {
  local src="$1" target_root="$2" name dest
  name="$(basename "$src")"
  dest="$target_root/$name"
  copy_tree "$src" "$dest"
  echo "installed $dest"
}

for t in "${targets[@]}"; do
  mkdir -p "$t"

  deploy_dest="$t/$DEPLOY_NAME"
  if [[ -d "$deploy_dest/.git" ]]; then
    git -C "$deploy_dest" pull --ff-only --quiet
    echo "updated   $deploy_dest"
  else
    copy_tree "$SRC" "$deploy_dest"
    echo "installed $deploy_dest"
  fi

  if [[ "$install_core" == "1" && -d "$SRC/skills/core" ]]; then
    while IFS= read -r -d '' skill_dir; do
      install_skill_dir "$skill_dir" "$t"
    done < <(find "$SRC/skills/core" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
  fi

  if [[ "$install_extras" == "1" && -d "$SRC/skills/extra" ]]; then
    while IFS= read -r -d '' skill_dir; do
      install_skill_dir "$skill_dir" "$t"
    done < <(find "$SRC/skills/extra" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
  fi
done

if [[ "$install_plugins" == "1" ]]; then
  amp_plugin_src="$SRC/plugins/amp/origingame.ts"
  if [[ -f "$amp_plugin_src" ]]; then
    if [[ "$target_mode" == "--project" ]]; then
      amp_plugin_dest="$PWD/.amp/plugins/origingame.ts"
    else
      amp_plugin_dest="$HOME/.config/amp/plugins/origingame.ts"
    fi
    mkdir -p "$(dirname "$amp_plugin_dest")"
    cp "$amp_plugin_src" "$amp_plugin_dest"
    echo "installed $amp_plugin_dest"
    echo "reload Amp plugins from the command palette: plugins: reload"
  fi
fi

echo "done. Default skills: origingame-deploy, developing-origingame-games, using-origingame-assets, using-origingame-gateway."
