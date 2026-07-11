#!/usr/bin/env bash
# Canonical OriginGame auth env for skill scripts.
# Source this file:  source "$(dirname "$0")/og-env.sh"
#
# | Purpose     | Canonical   | Legacy aliases                          |
# |-------------|-------------|-----------------------------------------|
# | sk- API key | OG_API_KEY  | ORIGINGAME_SK_KEY                       |
# | Portal host | OG_HOST     | ORIGINGAME_DEPLOY_ORIGIN, ORIGINGAME_HOST |

# Prefer canonical names; promote aliases into canonical slots for child tools.
if [[ -z "${OG_API_KEY:-}" && -n "${ORIGINGAME_SK_KEY:-}" ]]; then
  export OG_API_KEY="$ORIGINGAME_SK_KEY"
fi
if [[ -z "${OG_HOST:-}" ]]; then
  if [[ -n "${ORIGINGAME_DEPLOY_ORIGIN:-}" ]]; then
    export OG_HOST="$ORIGINGAME_DEPLOY_ORIGIN"
  elif [[ -n "${ORIGINGAME_HOST:-}" ]]; then
    export OG_HOST="$ORIGINGAME_HOST"
  else
    export OG_HOST="http://localhost:8787"
  fi
fi

# Mirror for any legacy readers in the same process.
if [[ -n "${OG_API_KEY:-}" ]]; then
  export ORIGINGAME_SK_KEY="$OG_API_KEY"
fi
export ORIGINGAME_DEPLOY_ORIGIN="${OG_HOST}"
export ORIGINGAME_HOST="${OG_HOST}"

og_require_api_key() {
  if [[ -z "${OG_API_KEY:-}" ]]; then
    echo "error: set OG_API_KEY (sk-..., create one at \$OG_HOST/dashboard)." >&2
    echo "       legacy alias ORIGINGAME_SK_KEY is also accepted." >&2
    return 1
  fi
  if [[ "${OG_API_KEY}" != sk-* ]]; then
    echo "error: OG_API_KEY must start with sk-" >&2
    return 1
  fi
}
