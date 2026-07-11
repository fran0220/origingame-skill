#!/usr/bin/env bash
# OriginGame Gateway helper for the /gw OpenAI-compatible proxy.
# usage:
#   gateway.sh models
#   gateway.sh chat "Say hello" [--model MODEL]
#   gateway.sh raw GET /v1/models [json-body]
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=og-env.sh
source "$SCRIPT_DIR/og-env.sh"
CMD="${1:-}"
[[ -n "$CMD" ]] || { echo "usage: gateway.sh models|chat|raw ..." >&2; exit 1; }
shift || true

need_key() {
  og_require_api_key
}

need_py() {
  command -v python3 >/dev/null || { echo "python3 is required" >&2; exit 1; }
}

case "$CMD" in
  models)
    need_key
    curl -fsS "$OG_HOST/gw/v1/models" \
      -H "Authorization: Bearer $OG_API_KEY"
    echo
    ;;
  chat)
    need_key
    need_py
    PROMPT="${1:-}"
    [[ -n "$PROMPT" ]] || { echo "usage: gateway.sh chat <prompt> [--model MODEL]" >&2; exit 1; }
    shift
    MODEL="${OG_MODEL:-claude-sonnet-4-6}"
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --model) MODEL="$2"; shift 2 ;;
        *) echo "unknown option: $1" >&2; exit 1 ;;
      esac
    done
    BODY=$(python3 - "$MODEL" "$PROMPT" <<'PY'
import json, sys
model, prompt = sys.argv[1], sys.argv[2]
print(json.dumps({
    "model": model,
    "messages": [{"role": "user", "content": prompt}],
}, ensure_ascii=False))
PY
)
    curl -fsS "$OG_HOST/gw/v1/chat/completions" \
      -H "Authorization: Bearer $OG_API_KEY" \
      -H 'Content-Type: application/json' \
      --data "$BODY"
    echo
    ;;
  raw)
    need_key
    METHOD="${1:-}"; PATH_IN="${2:-}"; BODY="${3:-}"
    [[ -n "$METHOD" && -n "$PATH_IN" ]] || { echo "usage: gateway.sh raw METHOD /v1/path [json-body]" >&2; exit 1; }
    case "$PATH_IN" in
      /v1/*|/api/*) ;;
      *) echo "raw path must start with /v1/ or /api/" >&2; exit 1 ;;
    esac
    args=(-fsS -X "$METHOD" "$OG_HOST/gw$PATH_IN" -H "Authorization: Bearer $OG_API_KEY")
    if [[ -n "$BODY" ]]; then args+=(-H 'Content-Type: application/json' --data "$BODY"); fi
    curl "${args[@]}"
    echo
    ;;
  *)
    echo "unknown command: $CMD" >&2
    exit 1
    ;;
esac
