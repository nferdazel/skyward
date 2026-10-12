import { describe, expect, it } from 'vitest';

// Baca sumber semua modul di core/ (Vite mentah) untuk menegakkan batas lapisan.
// Aturan: core/ tidak boleh bergantung pada features/ — kecuali core/di/
// (composition root). Dulu dilanggar tanpa sinyal karena semuanya `import type`.
const coreSources = import.meta.glob('./**/*.{ts,svelte}', {
	eager: true,
	query: '?raw',
	import: 'default'
}) as Record<string, string>;

const FEATURE_IMPORT = /from\s+['"]\$lib\/features\//;

describe('batas lapisan core → features', () => {
	it('tidak ada modul core (selain core/di) yang mengimpor features', () => {
		const offenders = Object.entries(coreSources)
			.filter(([path]) => !path.includes('/di/') && !path.includes('.test.'))
			.filter(([, source]) => FEATURE_IMPORT.test(source))
			.map(([path]) => path);

		expect(offenders).toEqual([]);
	});
});
