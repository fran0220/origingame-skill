#!/usr/bin/env bash
# Validate an OriginGame web-game directory before deploy.
# usage: dev-check.sh <game-dir>
set -euo pipefail

DIR="${1:-}"
if [[ -z "$DIR" ]]; then
  echo "usage: dev-check.sh <game-dir>" >&2
  exit 1
fi

fail=0
warn=0

say() { printf '%s\n' "$*"; }
bad() { say "error: $*" >&2; fail=1; }
note() { say "warn:  $*" >&2; warn=1; }

[[ -d "$DIR" ]] || bad "$DIR is not a directory"
[[ -f "$DIR/index.html" ]] || bad "$DIR/index.html not found"

if [[ -d "$DIR/node_modules" ]]; then note "node_modules/ is present; deploy.sh excludes it but the project should deploy a lean build output"; fi
if [[ -d "$DIR/.git" ]]; then note ".git/ is present; deploy.sh excludes it"; fi
if find "$DIR" -type f -name '*.map' -print -quit 2>/dev/null | grep -q .; then note "source maps are present; deploy.sh excludes *.map"; fi

if [[ -f "$DIR/index.html" ]]; then
  if grep -nE '(src|href)="/[^/]' "$DIR/index.html" >/tmp/og-abs-paths.$$ 2>/dev/null; then
    note "index.html contains root-absolute asset paths; prefer ./assets/... for deploy portability"
    sed 's/^/       /' /tmp/og-abs-paths.$$ >&2 || true
  fi
  rm -f /tmp/og-abs-paths.$$
  if ! grep -q 'window\.OG\|OG\?\.ready\|\.ready()' "$DIR/index.html" 2>/dev/null; then
    note "no obvious OG SDK usage found; this is fine for simple games, but call window.OG?.ready() after load when using platform features"
  fi
fi

if command -v du >/dev/null; then
  bytes=$(du -sk "$DIR" 2>/dev/null | awk '{print $1 * 1024}')
  if [[ -n "${bytes:-}" && "$bytes" -gt $((80 * 1024 * 1024)) ]]; then
    note "directory is larger than 80MB; consider deploying a bundled/minified output"
  fi
fi

if [[ "$fail" == "1" ]]; then
  exit 1
fi

if [[ "$warn" == "1" ]]; then
  say "ok with warnings: $DIR can be deployed after reviewing warnings"
else
  say "ok: $DIR looks deployable"
fi
