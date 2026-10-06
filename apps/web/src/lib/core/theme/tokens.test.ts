import { describe, expect, it } from 'vitest';
import { colors } from './tokens';

/**
 * WCAG 2.x contrast ratio between two hex colours.
 * Guards the design tokens against regressions below AA (4.5:1 normal text).
 */
function luminance(hex: string): number {
	const h = hex.replace('#', '');
	const channel = (i: number) => parseInt(h.slice(i, i + 2), 16) / 255;
	const lin = (c: number) => (c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4);
	const [r, g, b] = [channel(0), channel(2), channel(4)].map(lin);
	return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

function ratio(a: string, b: string): number {
	const la = luminance(a);
	const lb = luminance(b);
	const [hi, lo] = la > lb ? [la, lb] : [lb, la];
	return (hi + 0.05) / (lo + 0.05);
}

const surfaces = {
	surface: colors.surface,
	surface2: colors.surface2,
	surface3: colors.surface3,
	surfaceActive: colors.surfaceActive
};

describe('design token contrast (WCAG AA)', () => {
	it('primary/secondary/muted text pass 4.5:1 on every surface', () => {
		for (const [name, bg] of Object.entries(surfaces)) {
			expect(ratio(colors.textPrimary, bg), `primary on ${name}`).toBeGreaterThanOrEqual(4.5);
			expect(ratio(colors.textSecondary, bg), `secondary on ${name}`).toBeGreaterThanOrEqual(4.5);
			expect(ratio(colors.textMuted, bg), `muted on ${name}`).toBeGreaterThanOrEqual(4.5);
		}
	});

	it('semantic colours pass 4.5:1 on the base surface', () => {
		for (const c of [colors.accent, colors.success, colors.warning, colors.error, colors.teal]) {
			expect(ratio(c, colors.surface), c).toBeGreaterThanOrEqual(4.5);
		}
	});

	it('accent passes on the active surface (selected rows)', () => {
		expect(ratio(colors.accent, colors.surfaceActive)).toBeGreaterThanOrEqual(4.5);
	});
});
