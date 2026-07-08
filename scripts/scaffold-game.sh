#!/usr/bin/env bash
# Create a dependency-free OriginGame canvas starter.
# usage: scaffold-game.sh <dir> [--title "Game Title"]
set -euo pipefail

DIR="${1:-}"
if [[ -z "$DIR" ]]; then
  echo "usage: scaffold-game.sh <dir> [--title \"Game Title\"]" >&2
  exit 1
fi
shift

TITLE="OriginGame Starter"
while [[ $# -gt 0 ]]; do
  case "$1" in
    --title) TITLE="$2"; shift 2 ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
done

if [[ -e "$DIR" ]] && [[ -n "$(find "$DIR" -mindepth 1 -maxdepth 1 -print -quit 2>/dev/null)" ]]; then
  echo "error: $DIR already exists and is not empty" >&2
  exit 1
fi

command -v python3 >/dev/null || { echo "python3 is required" >&2; exit 1; }
mkdir -p "$DIR"

python3 - "$DIR/index.html" "$TITLE" <<'PY'
import html
import pathlib
import sys

out = pathlib.Path(sys.argv[1])
title = html.escape(sys.argv[2])
out.write_text(f'''<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1, viewport-fit=cover" />
  <title>{title}</title>
  <style>
    html, body {{ margin: 0; height: 100%; background: #101014; color: #fff; font-family: system-ui, sans-serif; }}
    #game {{ display: block; width: 100vw; height: 100vh; touch-action: none; }}
    #hud {{ position: fixed; left: 12px; top: 12px; padding: 8px 10px; border: 1px solid #ffffff33; background: #0008; border-radius: 8px; }}
    #hint {{ position: fixed; right: 12px; bottom: 12px; opacity: .75; font-size: 13px; }}
  </style>
</head>
<body>
  <canvas id="game"></canvas>
  <div id="hud">Score: <b id="score">0</b></div>
  <div id="hint">Move: WASD / arrows · Save: P · Leaderboard: L</div>
  <script>
    const og = window.OG ?? null
    og?.ready().catch(console.warn)

    const canvas = document.getElementById('game')
    const ctx = canvas.getContext('2d')
    const scoreEl = document.getElementById('score')
    const keys = new Set()
    const player = {{ x: 120, y: 120, r: 14, speed: 240 }}
    const coin = {{ x: 300, y: 200, r: 10 }}
    let score = 0
    let last = performance.now()

    addEventListener('keydown', e => {{ keys.add(e.key.toLowerCase()); if (e.key.toLowerCase() === 'p') save(); if (e.key.toLowerCase() === 'l') showLeaderboard(); }})
    addEventListener('keyup', e => keys.delete(e.key.toLowerCase()))
    addEventListener('resize', resize)

    function resize() {{ canvas.width = innerWidth * devicePixelRatio; canvas.height = innerHeight * devicePixelRatio; ctx.setTransform(devicePixelRatio, 0, 0, devicePixelRatio, 0, 0) }}
    function rand(max) {{ return Math.max(30, Math.random() * (max - 60) + 30) }}
    function collect() {{ score += 10; scoreEl.textContent = String(score); coin.x = rand(innerWidth); coin.y = rand(innerHeight); og?.leaderboard.submit(score).catch(() => {{}}) }}
    async function save() {{ await og?.save.set({{ score, player }}).catch(console.warn) }}
    async function load() {{ const data = await og?.save.get().catch(() => null); if (data?.player) Object.assign(player, data.player); if (data?.score) {{ score = data.score; scoreEl.textContent = String(score) }} }}
    async function showLeaderboard() {{ const board = await og?.leaderboard.top(5).catch(() => null); if (board) console.table(board.top) }}

    function frame(now) {{
      const dt = Math.min(0.033, (now - last) / 1000); last = now
      const dx = (keys.has('arrowright') || keys.has('d')) - (keys.has('arrowleft') || keys.has('a'))
      const dy = (keys.has('arrowdown') || keys.has('s')) - (keys.has('arrowup') || keys.has('w'))
      player.x = Math.max(player.r, Math.min(innerWidth - player.r, player.x + dx * player.speed * dt))
      player.y = Math.max(player.r, Math.min(innerHeight - player.r, player.y + dy * player.speed * dt))
      if (Math.hypot(player.x - coin.x, player.y - coin.y) < player.r + coin.r) collect()

      ctx.clearRect(0, 0, innerWidth, innerHeight)
      ctx.fillStyle = '#181820'; ctx.fillRect(0, 0, innerWidth, innerHeight)
      ctx.fillStyle = '#ffb100'; ctx.beginPath(); ctx.arc(coin.x, coin.y, coin.r, 0, Math.PI * 2); ctx.fill()
      ctx.fillStyle = '#f4efe4'; ctx.beginPath(); ctx.arc(player.x, player.y, player.r, 0, Math.PI * 2); ctx.fill()
      requestAnimationFrame(frame)
    }}

    resize(); load(); requestAnimationFrame(frame)
  </script>
</body>
</html>
''', encoding='utf-8')
PY

echo "created $DIR/index.html"
echo "next: python3 -m http.server 8080 -d '$DIR'"
