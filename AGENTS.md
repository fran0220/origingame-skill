# OriginGame Plugin guidance

`skill/origingame-deploy/` is the in-repository source of truth for the published OriginGame Plugin. Never edit the separately published `origingame-skill` repository directly.

- Preserve the plugin/skill tree and backward-compatible deploy root.
- New docs and scripts use `OG_API_KEY` and `OG_HOST`; legacy aliases remain compatibility inputs only.
- Agents discover assets through the asset MCP first. `scripts/assets.sh` and raw `/api/assets/*` are fallbacks when MCP is unavailable.
- Keep Gateway integration HTTP-only and never embed secrets in generated docs, logs, examples, or committed files.
- Shared workbench behavior should match `@origingame/origin-workbench-core`, not be reimplemented independently.

Validate from the repository root with `npm run skill:validate`; run `npm run skill:parity` for shared behavior changes. `npm run skill:publish` is a shared remote action and requires explicit user approval.
