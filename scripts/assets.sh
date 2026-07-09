#!/usr/bin/env bash
# OriginGame asset helper (REST convenience wrapper; agents should prefer the asset MCP at
# asset-mcp.origingame.dev). Bundles use the server fetch-plan (no zip): glTF/GLB primary + resources.
# usage:
#   assets.sh search "low poly medieval knight" [--kind 3d] [--theme fantasy] [--format glb] [--limit 10]
#   assets.sh show <group-id>
#   assets.sh get <file-id> --out ./assets/origingame
#   assets.sh bundle [--group <group-id>] [--file <file-id>] [--format glb|gltf] --out ./assets/origingame
set -euo pipefail

OG_HOST="${OG_HOST:-http://localhost:8787}"
CMD="${1:-}"
[[ -n "$CMD" ]] || { echo "usage: assets.sh search|get|bundle ..." >&2; exit 1; }
shift || true

auth_args=()
if [[ -n "${OG_API_KEY:-}" ]]; then auth_args=(-H "Authorization: Bearer $OG_API_KEY"); fi

need_py() { command -v python3 >/dev/null || { echo "python3 is required" >&2; exit 1; }; }

case "$CMD" in
  search)
    need_py
    QUERY="${1:-}"; [[ -n "$QUERY" ]] || { echo "usage: assets.sh search <query> [filters]" >&2; exit 1; }
    shift
    LIMIT="10"
    declare -a PARAMS=("q=$QUERY")
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --limit) LIMIT="$2"; shift 2 ;;
        --kind|--media_type|--game_genre|--theme|--visual_style|--camera_view|--role|--environment|--format|--engine_hint|--usage_hint)
          key="${1#--}"; PARAMS+=("$key=$2"); shift 2 ;;
        *) echo "unknown option: $1" >&2; exit 1 ;;
      esac
    done
    PARAMS+=("limit=$LIMIT")
    URL=$(python3 - "$OG_HOST" "${PARAMS[@]}" <<'PY'
import sys, urllib.parse
host=sys.argv[1].rstrip('/')
params=[]
for item in sys.argv[2:]:
    k,v=item.split('=',1); params.append((k,v))
print(host + '/api/assets/search?' + urllib.parse.urlencode(params))
PY
)
    JSON=$(curl -fsS "$URL")
    python3 - "$JSON" <<'PY'
import json, sys
d=json.loads(sys.argv[1])
for i,item in enumerate(d.get('items', []), 1):
    tags=', '.join(t['value'] for t in item.get('tags', []) if t['facet'] in ('game_genre','theme','visual_style','role','media_type'))
    print(f"{i}. {item['title']}  [{item['id']}]")
    print(f"   pack: {item['packName']} / {item['category']} · files: {item['fileCount']} · formats: {', '.join(item.get('formats', []))}")
    if tags: print(f"   tags: {tags}")
    print(f"   preview: {item.get('previewFileId') or '-'}")
print('\nraw_json:')
print(json.dumps(d, ensure_ascii=False, indent=2))
PY
    ;;
  show)
    need_py
    ID="${1:-}"; [[ -n "$ID" ]] || { echo "usage: assets.sh show <group-id>" >&2; exit 1; }
    JSON=$(curl -fsS "$OG_HOST/api/assets/groups/$ID")
    python3 - "$JSON" <<'PY'
import json, sys
d=json.loads(sys.argv[1])
g=d['group']
print(f"{g['title']} [{g['id']}]")
print(f"pack: {g['packName']} / {g['category']} · files: {g['fileCount']} · formats: {', '.join(g.get('formats', []))}")
if g.get('summaryEn'): print(g['summaryEn'])
tags=', '.join(t['value'] for t in g.get('tags', []) if t['facet'] in ('game_genre','theme','visual_style','role','media_type','environment'))
if tags: print(f"tags: {tags}")
print('\nfiles:')
for f in g.get('files', []):
    dim = f" · {f['width']}x{f['height']}" if f.get('width') and f.get('height') else ''
    print(f"- {f['basename']}  [{f['id']}]  {f['format'].upper()} · {f['sizeBytes']} bytes{dim}")
print('\nraw_json:')
print(json.dumps(d, ensure_ascii=False, indent=2))
PY
    ;;
  get)
    need_py
    ID="${1:-}"; [[ -n "$ID" ]] || { echo "usage: assets.sh get <file-id> --out <dir>" >&2; exit 1; }
    shift
    OUT="./assets/origingame"
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --out) OUT="$2"; shift 2 ;;
        *) echo "unknown option: $1" >&2; exit 1 ;;
      esac
    done
    mkdir -p "$OUT"
    META=$(curl -fsS "$OG_HOST/api/assets/files/$ID/meta")
    NAME=$(python3 -c 'import json,sys; print(json.load(sys.stdin)["file"]["basename"])' <<<"$META")
    curl -fL "${auth_args[@]}" "$OG_HOST/api/assets/files/$ID" -o "$OUT/$NAME"
    python3 - "$OUT/asset-manifest.json" "$META" <<'PY'
import json, pathlib, sys
p=pathlib.Path(sys.argv[1])
old=[]
if p.exists():
    try: old=json.loads(p.read_text()).get('files', [])
    except Exception: old=[]
file=json.loads(sys.argv[2])['file']
seen={x.get('id') for x in old}
if file['id'] not in seen: old.append(file)
p.write_text(json.dumps({'source':'OriginGame asset library','license':'CC0','files':old}, ensure_ascii=False, indent=2))
PY
    cat > "$OUT/ATTRIBUTION.txt" <<'TXT'
OriginGame asset library (Kenney, KayKit, Quaternius, and more)
License: Creative Commons Zero (CC0)
https://creativecommons.org/publicdomain/zero/1.0/
Credit to the original creators is appreciated but not required.
TXT
    echo "saved $OUT/$NAME"
    ;;
  bundle)
    # No zip: the server returns a fetch-plan (direct per-file URLs + target paths). We download each
    # file (glTF primary + its .bin/textures) into --out, preserving the plan's relative layout.
    need_py
    OUT="./assets/origingame"
    FORMAT=""
    declare -a FILE_IDS=()
    declare -a GROUP_IDS=()
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --out) OUT="$2"; shift 2 ;;
        --file) FILE_IDS+=("$2"); shift 2 ;;
        --group) GROUP_IDS+=("$2"); shift 2 ;;
        --format) FORMAT="$2"; shift 2 ;;
        *) echo "unknown option: $1" >&2; exit 1 ;;
      esac
    done
    BODY=$(python3 - "${FILE_IDS[*]}" "${GROUP_IDS[*]}" "$FORMAT" <<'PY'
import json, sys
def xs(s): return [x for x in s.split() if x]
body={'fileIds': xs(sys.argv[1]), 'groupIds': xs(sys.argv[2])}
if sys.argv[3]: body['format']=sys.argv[3]
print(json.dumps(body))
PY
)
    PLAN=$(curl -fsS -X POST "${auth_args[@]}" -H 'Content-Type: application/json' --data "$BODY" "$OG_HOST/api/assets/bundle")
    # Emit "targetRelPath<TAB>downloadURL" lines (host rewritten to OG_HOST), plus attribution
    # and the asset-manifest.json that deploy.sh auto-detects for portal attribution.
    # Plan is passed as argv: the heredoc owns stdin, so piping it would be silently dropped.
    python3 - "$PLAN" "$OG_HOST" "$OUT" <<'PY' | while IFS=$'\t' read -r REL URL; do
import json, sys, urllib.parse
plan=json.loads(sys.argv[1])
host=sys.argv[2].rstrip('/')
out=sys.argv[3]
base=(plan.get('targetDir') or 'assets/origingame').rstrip('/')+'/'
for f in plan.get('files', []):
    tp=f['targetPath']
    rel=tp[len(base):] if tp.startswith(base) else tp
    u=urllib.parse.urlparse(f['url'])
    url=host + u.path + (('?'+u.query) if u.query else '')
    print(rel+'\t'+url)
import pathlib
pathlib.Path(out).mkdir(parents=True, exist_ok=True)
cred='\n'.join(a.get('credit','') for a in plan.get('attribution', []))
(pathlib.Path(out)/'ATTRIBUTION.txt').write_text((cred or 'CC0')+'\n')
manifest=plan.get('manifest')
if manifest:
    (pathlib.Path(out)/'asset-manifest.json').write_text(json.dumps(manifest, ensure_ascii=False, indent=2)+'\n')
PY
      DEST="$OUT/$REL"
      mkdir -p "$(dirname "$DEST")"
      curl -fL "${auth_args[@]}" "$URL" -o "$DEST"
    done
    echo "fetched bundle into $OUT"
    ;;
  *)
    echo "unknown command: $CMD" >&2; exit 1 ;;
esac
