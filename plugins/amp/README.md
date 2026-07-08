# OriginGame Amp Plugin

Adds command-palette actions for common OriginGame workflows:

- `OriginGame: Open dashboard`
- `OriginGame: Build game prompt`
- `OriginGame: Deploy game prompt`
- `OriginGame: Gateway smoke-test prompt`
- `OriginGame: Search assets prompt`

Install globally:

```bash
mkdir -p ~/.config/amp/plugins
cp plugins/amp/origingame.ts ~/.config/amp/plugins/origingame.ts
```

Install project-locally:

```bash
mkdir -p .amp/plugins
cp plugins/amp/origingame.ts .amp/plugins/origingame.ts
```

Then run `plugins: reload` from Amp's command palette.

The plugin intentionally appends prompts to the active thread instead of directly deploying or making Gateway calls. That keeps high-impact actions behind the normal agent/tool approval path.
