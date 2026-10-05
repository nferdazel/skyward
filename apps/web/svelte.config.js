import adapter from '@sveltejs/adapter-static';
import { vitePreprocess } from '@sveltejs/vite-plugin-svelte';

/**
 * Skyward web client.
 *
 * Static output (no SSR, no Node runtime in production): the build directory is
 * served directly by Caddy. All data comes from skyward-api over REST + WS.
 *
 * `fallback: 'index.html'` makes the SPA work on deep-link refresh: the static
 * host rewrites unknown paths to index.html and the client router takes over.
 */
/** @type {import('@sveltejs/kit').Config} */
const config = {
	preprocess: vitePreprocess(),
	kit: {
		adapter: adapter({
			fallback: 'index.html'
		})
	}
};

export default config;
