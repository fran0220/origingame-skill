#!/usr/bin/env bash
# Validate the published OriginGame skill ecosystem tree.
# usage: validate-skill-tree.sh [skill-root]
set -euo pipefail

ROOT="${1:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
fail=0

bad() { echo "error: $*" >&2; fail=1; }
ok() { echo "ok: $*"; }

[[ -f "$ROOT/SKILL.md" ]] || bad "$ROOT/SKILL.md missing"

check_skill() {
  local dir="$1" name expected
  expected="$(basename "$dir")"
  [[ -f "$dir/SKILL.md" ]] || { bad "$dir/SKILL.md missing"; return; }
  name="$(awk -F': *' '/^name:/{print $2; exit}' "$dir/SKILL.md" | tr -d '"' | tr -d "'")"
  [[ -n "$name" ]] || bad "$dir/SKILL.md missing frontmatter name"
  [[ "$name" == "$expected" ]] || bad "$dir/SKILL.md name '$name' does not match directory '$expected'"
  if ! awk '/^description:/{found=1} END{exit found?0:1}' "$dir/SKILL.md"; then
    bad "$dir/SKILL.md missing description"
  fi
}

check_skill "$ROOT"
for base in "$ROOT/skills/core" "$ROOT/skills/extra"; do
  [[ -d "$base" ]] || continue
  while IFS= read -r -d '' skill_dir; do
    check_skill "$skill_dir"
  done < <(find "$base" -mindepth 1 -maxdepth 1 -type d -print0 | sort -z)
done

while IFS= read -r -d '' sh; do
  bash -n "$sh" || bad "bash syntax failed: $sh"
done < <(find "$ROOT" -type f -name '*.sh' -print0 | sort -z)
ok "shell scripts parsed"

if [[ -f "$ROOT/plugins/amp/origingame.ts" ]]; then
  if grep -q "registerCommand" "$ROOT/plugins/amp/origingame.ts"; then
    ok "Amp plugin declares command palette actions"
  else
    bad "Amp plugin has no registerCommand call"
  fi
fi

PARITY_DOC="$ROOT/docs/ecosystem.md"
if [[ -f "$PARITY_DOC" ]]; then
  for skill in og-develop og-assets og-gateway og-check og-deploy og-review og-annotate og-last; do
    grep -q "\`$skill\`" "$PARITY_DOC" || bad "$PARITY_DOC missing workbench parity entry for $skill"
  done
  [[ -d "$ROOT/skills/core/developing-origingame-games" ]] || bad "missing lightweight parity skill: developing-origingame-games"
  [[ -d "$ROOT/skills/core/using-origingame-assets" ]] || bad "missing lightweight parity skill: using-origingame-assets"
  [[ -d "$ROOT/skills/core/using-origingame-gateway" ]] || bad "missing lightweight parity skill: using-origingame-gateway"
  [[ -f "$ROOT/scripts/assets.sh" ]] || bad "missing lightweight parity script: assets.sh"
  [[ -f "$ROOT/scripts/gateway.sh" ]] || bad "missing lightweight parity script: gateway.sh"
  [[ -f "$ROOT/scripts/dev-check.sh" ]] || bad "missing lightweight parity script: dev-check.sh"
  [[ -f "$ROOT/scripts/deploy.sh" ]] || bad "missing lightweight parity script: deploy.sh"
  ok "workbench/lightweight parity documented"
else
  bad "$PARITY_DOC missing"
fi

[[ "$fail" == "0" ]] || exit 1
ok "skill tree valid"
