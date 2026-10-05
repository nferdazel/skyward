import { sveltekit } from '@sveltejs/kit/vite';
import { defineConfig } from 'vitest/config';

export default defineConfig({
	plugins: [sveltekit()],
	resolve: {
		// Paksa resolusi ke kondisi browser. Tanpa ini, @testing-library/svelte
		// mengambil build SSR Svelte dan `mount()` gagal (Svelte 5 + vitest).
		conditions: ['browser']
	},
	test: {
		include: ['src/**/*.{test,spec}.{js,ts}'],
		environment: 'jsdom',
		globals: true,
		setupFiles: ['src/test/setup.ts']
	}
});
