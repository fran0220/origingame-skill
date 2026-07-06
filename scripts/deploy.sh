#!/usr/bin/env bash
# OriginGame deploy helper.
# usage: deploy.sh <game-dir> --title "My Game" [--engine html|threejs|godot]
#        [--license protected|open] [--license-name MIT] [--source-url URL]
#        [--description TEXT] [--orientation any|landscape|portrait] [--aspect 16:9]
#        [--max-players N] [--unlisted] [--cover PATH] [--update GAME_ID]
set -euo pipefail

OG_HOST="${OG_HOST:-http://localhost:8787}"
: "${OG_API_KEY:?set OG_API_KEY (sk-..., create one in the console at \$OG_HOST/console)}"

DIR="${1:?usage: deploy.sh <game-dir> --title \"My Game\" [options]}"
shift

TITLE="" ENGINE="html" LICENSE="protected" LICENSE_NAME="" SOURCE_URL=""
DESCRIPTION="" ORIENTATION="any" ASPECT="" MAX_PLAYERS="1" UNLISTED="0" COVER="" UPDATE_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --title) TITLE="$2"; shift 2 ;;
    --engine) ENGINE="$2"; shift 2 ;;
    --license) LICENSE="$2"; shift 2 ;;
    --license-name) LICENSE_NAME="$2"; shift 2 ;;
    --source-url) SOURCE_URL="$2"; shift 2 ;;
    --description) DESCRIPTION="$2"; shift 2 ;;
    --orientation) ORIENTATION="$2"; shift 2 ;;
    --aspect) ASPECT="$2"; shift 2 ;;
    --max-players) MAX_PLAYERS="$2"; shift 2 ;;
    --unlisted) UNLISTED="1"; shift ;;
    --cover) COVER="$2"; shift 2 ;;
    --update) UPDATE_ID="$2"; shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

[[ -f "$DIR/index.html" ]] || { echo "error: $DIR/index.html not found" >&2; exit 1; }
[[ -n "$TITLE" || -n "$UPDATE_ID" ]] || { echo "error: --title is required" >&2; exit 1; }

ZIP="$(mktemp -t oggame).zip"
trap 'rm -f "$ZIP"' EXIT
(cd "$DIR" && zip -qr "$ZIP" . -x "node_modules/*" -x ".git/*" -x "*.map")

ARGS=(-sS -H "Authorization: Bearer $OG_API_KEY" -F "file=@$ZIP;type=application/zip")
[[ -n "$TITLE" ]] && ARGS+=(-F "title=$TITLE")
ARGS+=(-F "engine=$ENGINE" -F "license_mode=$LICENSE" -F "orientation=$ORIENTATION" -F "max_players=$MAX_PLAYERS")
[[ -n "$LICENSE_NAME" ]] && ARGS+=(-F "license_name=$LICENSE_NAME")
[[ -n "$SOURCE_URL" ]] && ARGS+=(-F "source_url=$SOURCE_URL")
[[ -n "$DESCRIPTION" ]] && ARGS+=(-F "description=$DESCRIPTION")
[[ -n "$ASPECT" ]] && ARGS+=(-F "aspect=$ASPECT")
[[ "$UNLISTED" == "1" ]] && ARGS+=(-F "unlisted=1")
[[ -n "$COVER" ]] && ARGS+=(-F "cover=@$COVER")

if [[ -n "$UPDATE_ID" ]]; then
  curl -X PUT "${ARGS[@]}" "$OG_HOST/api/deploy/$UPDATE_ID"
else
  curl -X POST "${ARGS[@]}" "$OG_HOST/api/deploy"
fi
echo
