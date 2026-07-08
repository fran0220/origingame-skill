import type { PluginAPI, PluginCommandContext } from '@ampcode/plugin'

const CATEGORY = 'OriginGame'

function configuredHost(): string {
	return process.env.OG_HOST || 'https://origingame.dev'
}

function urlFor(path: string): URL {
	const base = configuredHost().endsWith('/') ? configuredHost() : configuredHost() + '/'
	return new URL(path.replace(/^\//, ''), base)
}

async function appendPrompt(ctx: PluginCommandContext, content: string): Promise<void> {
	if (!ctx.thread) {
		await ctx.ui.notify('Open or create an Amp thread first, then run this OriginGame command again.')
		return
	}
	await ctx.thread.appendUserMessage({ type: 'user-message', content }, { steer: true })
}

export default function (amp: PluginAPI) {
	amp.registerCommand(
		'origingame-open-dashboard',
		{
			title: 'Open dashboard',
			category: CATEGORY,
			description: 'Open the OriginGame dashboard for API keys, quota, deployments, and Studio launch.',
		},
		async (ctx) => {
			await ctx.system.open(urlFor('/dashboard'))
			await ctx.ui.notify(`Opened ${urlFor('/dashboard').toString()}`)
		},
	)

	amp.registerCommand(
		'origingame-build-game-prompt',
		{
			title: 'Build game prompt',
			category: CATEGORY,
			description: 'Ask the active thread to build an OriginGame-compatible web game.',
		},
		async (ctx) => {
			const idea = await ctx.ui.input({
				title: 'Game idea',
				helpText: 'Describe the game loop, style, controls, and any SDK features to include.',
				initialValue: 'Build a small polished HTML canvas arcade game for OriginGame with keyboard/touch controls, leaderboard, and cloud save.',
				submitButtonText: 'Send to thread',
			})
			if (!idea) return
			await appendPrompt(ctx, `Use the developing-origingame-games skill. ${idea}\n\nDeliver a playable game directory with index.html at the root, relative asset paths, guarded window.OG usage, and a pre-deploy check.`)
		},
	)

	amp.registerCommand(
		'origingame-deploy-game-prompt',
		{
			title: 'Deploy game prompt',
			category: CATEGORY,
			description: 'Ask the active thread to deploy a game directory to OriginGame.',
		},
		async (ctx) => {
			const dir = await ctx.ui.input({
				title: 'Game directory',
				helpText: 'Path to the built game directory. It must contain index.html at the root.',
				initialValue: './dist',
				submitButtonText: 'Next',
			})
			if (!dir) return
			const title = await ctx.ui.input({
				title: 'Game title',
				initialValue: 'My OriginGame',
				submitButtonText: 'Send to thread',
			})
			if (!title) return
			await appendPrompt(ctx, `Use the origingame-deploy skill. Validate and deploy ${dir} to ${configuredHost()} with title ${JSON.stringify(title)}. If OG_API_KEY is missing, ask me to create one at ${urlFor('/dashboard').toString()}. Report playUrl and portalUrl.`)
		},
	)

	amp.registerCommand(
		'origingame-gateway-smoke-test-prompt',
		{
			title: 'Gateway smoke-test prompt',
			category: CATEGORY,
			description: 'Ask the active thread to validate the OriginGame Gateway /gw/v1 proxy with the configured API key.',
		},
		async (ctx) => {
			await appendPrompt(ctx, `Use the using-origingame-gateway skill. Validate the Gateway proxy at ${configuredHost()} by calling /gw/v1/models with OG_API_KEY. Do not print the key. Report whether the key works and summarize available model ids if the response includes them.`)
		},
	)

	amp.registerCommand(
		'origingame-asset-search-prompt',
		{
			title: 'Search assets prompt',
			category: CATEGORY,
			description: 'Ask the active thread to search the OriginGame/Kenney asset library.',
		},
		async (ctx) => {
			const query = await ctx.ui.input({
				title: 'Asset search',
				helpText: 'Describe the art/audio/3D assets needed for the current game.',
				initialValue: 'pixel arcade player, obstacle, collectible, and UI button assets',
				submitButtonText: 'Send to thread',
			})
			if (!query) return
			await appendPrompt(ctx, `Use the using-origingame-assets skill. Search OriginGame assets for: ${query}. Prefer cohesive CC0 Kenney packs, inspect promising groups, and download only the files needed into the game project with attribution manifest.`)
		},
	)
}
