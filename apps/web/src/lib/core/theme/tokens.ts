/**
 * Skyward design tokens — dark "aviation command" system (PFD/ATC inspired).
 * Monochrome base; colour encodes operational meaning only.
 *
 * Ported faithfully from the Flutter client:
 *   core/theme/skyward_colors.dart, app_theme.dart,
 *   presentation/theme/{app_typography,app_motion,app_spacing}.dart
 */

export const colors = {
	// ── Backgrounds ──
	bg: '#080B10',
	surface: '#0F1319',
	surface2: '#161C25',
	surface3: '#1E2633',
	surfaceActive: '#242E3D',

	// ── Borders (zero-elevation architecture) ──
	border: 'rgba(255,255,255,0.10)',
	borderSubtle: 'rgba(255,255,255,0.05)',
	borderHighlight: 'rgba(255,255,255,0.15)',
	borderFocus: '#5B9EE0',

	// ── Primary: HUD blue ──
	accent: '#5B9EE0',
	accentBright: '#8DBFF0',
	accentSubtle: 'rgba(91,158,224,0.10)',
	accentGhost: 'rgba(91,158,224,0.05)',

	// ── Secondary: ATC teal ──
	teal: '#3AAFA0',
	tealSubtle: 'rgba(58,175,160,0.10)',

	// ── Semantic ──
	success: '#34D07B',
	successSubtle: 'rgba(52,208,123,0.10)',
	warning: '#E6A817',
	warningSubtle: 'rgba(230,168,23,0.10)',
	error: '#E05555',
	errorSubtle: 'rgba(224,85,85,0.10)',
	neutral: '#758489',

	// ── Tier / condition extras ──
	platinum: '#E5E4E2',
	gold: '#FFD700',
	orange: '#D98E4E',

	// ── Text ──
	// Contrast verified against WCAG AA (4.5:1 normal, 3:1 large) on the
	// darkest surface (#0F1319). The Flutter original claimed #64748B "passes
	// AA"; measured it is 3.91:1 on surface (4.14:1 on bg) — it failed. Corrected
	// to #8A99AD (6.42 / 5.90 / 4.72 on surface / surface2 / surface-active).
	textPrimary: '#DDE2EA',
	textSecondary: '#909FB3',
	textMuted: '#8A99AD'
} as const;

/** Spacing — 4px grid. */
export const spacing = {
	xs: 4,
	sm: 8,
	md: 12,
	lg: 16,
	xl: 20,
	xxl: 24,
	xxxl: 32,
	xxxxl: 40,
	xxxxxl: 48
} as const;

/** Semantic spacing aliases. */
export const space = {
	page: 16,
	card: 12,
	section: 16,
	block: 12,
	compact: 8,
	micro: 4
} as const;

/** Corner radii. */
export const radius = {
	tight: 2,
	default: 4,
	soft: 8,
	round: 12
} as const;

/** Motion tokens. */
export const motion = {
	fast: '120ms',
	base: '180ms',
	slow: '280ms',
	slower: '420ms',
	ease: 'cubic-bezier(0.2, 0, 0, 1)',
	easeOut: 'cubic-bezier(0, 0, 0.2, 1)',
	pressScale: 0.97
} as const;

/**
 * Aircraft condition → colour band. Ported from condition_colors.dart.
 * Bands are inclusive-low; thresholds match the Flutter thresholds.
 */
export function conditionColor(condition: number): string {
	if (condition >= 80) return colors.success;
	if (condition >= 50) return colors.warning;
	if (condition >= 30) return colors.orange;
	return colors.error;
}

/** Load-factor band → colour (used by route assessment views). */
export function loadFactorColor(loadFactorPercent: number): string {
	if (loadFactorPercent >= 80) return colors.success;
	if (loadFactorPercent >= 60) return colors.warning;
	return colors.error;
}

/** Operational status → colour. */
export function statusColor(status: string): string {
	switch (status.toLowerCase()) {
		case 'active':
		case 'operational':
			return colors.success;
		case 'grounded':
		case 'suspended':
			return colors.warning;
		case 'bankrupt':
			return colors.error;
		default:
			return colors.neutral;
	}
}

/** Credit tier → colour. */
export function creditTierColor(tier: string): string {
	switch (tier) {
		case 'Platinum':
			return colors.platinum;
		case 'Gold':
			return colors.gold;
		case 'Silver':
			return colors.neutral;
		case 'Subprime':
			return colors.error;
		default:
			return colors.textSecondary;
	}
}
