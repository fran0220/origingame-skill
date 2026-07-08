# OriginGame Plugin Adapters

Plugins are thin host-specific adapters over the published OriginGame skills and scripts. They should not become a second source of truth for deploy, Gateway, asset, or SDK behavior.

Current adapters:

- `amp/origingame.ts` — Amp command-palette commands that open dashboard URLs or append precise OriginGame prompts into the active thread.

Safety rules:

- Do not silently deploy, mutate production, or spend Gateway quota from a plugin command.
- Prefer asking/steering the active thread so the normal skill instructions and tool approvals still apply.
- Keep secrets in environment variables such as `OG_API_KEY`; plugins must not display them.
