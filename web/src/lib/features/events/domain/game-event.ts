/** Event dunia global (fuel shock, demand surge, weather, maintenance). */
export interface GameEvent {
	id: string;
	eventType: string;
	title: string;
	description: string;
	effectType: string;
	effectTarget: string;
	effectValue: number;
	startGameTime: string;
	endGameTime: string;
	isActive: boolean;
}

function str(v: unknown, fallback = ''): string {
	return typeof v === 'string' ? v : fallback;
}
function num(v: unknown, fallback = 0): number {
	return typeof v === 'number' && Number.isFinite(v) ? v : fallback;
}

export function gameEventFromMap(map: Record<string, unknown>): GameEvent {
	return {
		id: str(map.id),
		eventType: str(map.event_type),
		title: str(map.title),
		description: str(map.description),
		effectType: str(map.effect_type),
		effectTarget: str(map.effect_target),
		effectValue: num(map.effect_value, 1),
		startGameTime: str(map.start_game_time) || new Date(0).toISOString(),
		endGameTime: str(map.end_game_time) || new Date(0).toISOString(),
		isActive: map.is_active !== false
	};
}

/** Sisa durasi event (game-time; display-only — server juga menyaring). */
export function remainingMs(event: GameEvent, nowMs: number): number {
	const end = Date.parse(event.endGameTime);
	if (Number.isNaN(end)) return 0;
	return Math.max(0, end - nowMs);
}

export function isExpired(event: GameEvent, nowMs: number): boolean {
	const end = Date.parse(event.endGameTime);
	if (Number.isNaN(end)) return true;
	return nowMs >= end;
}
