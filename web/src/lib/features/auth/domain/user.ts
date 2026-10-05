/**
 * Pengguna Skyward. Port dari Flutter `AppUser`.
 *
 * Tidak ada `cashBalance` di sini: kas otoritatif ada di
 * `bank_accounts.balance` dan datang dari store bank/simulasi.
 */
export interface AppUser {
	id: string;
	username: string;
	companyName: string;
	ceoName: string;
	netWorth: number;
	gameCurrentTime: string;
	autoGroundingThreshold: number;
	hqAirportIata: string;
	operationalStatus: string;
	consecutiveNegativeDays: number;
	recoveryStreakDays: number;
	onboardingCompleted: boolean;
	actorType: string;
}

function str(value: unknown, fallback = ''): string {
	return typeof value === 'string' ? value : fallback;
}

function num(value: unknown, fallback = 0): number {
	return typeof value === 'number' && Number.isFinite(value) ? value : fallback;
}

export function userFromMap(map: Record<string, unknown>): AppUser {
	const gameTime = map.game_current_time;
	return {
		id: str(map.user_id ?? map.id),
		username: str(map.user_username ?? map.username),
		companyName: str(map.company_name),
		ceoName: str(map.ceo_name),
		netWorth: num(map.net_worth),
		gameCurrentTime: typeof gameTime === 'string' && gameTime ? gameTime : new Date().toISOString(),
		autoGroundingThreshold: num(map.auto_grounding_threshold, 30),
		hqAirportIata: str(map.hq_airport_iata, 'SIN'),
		operationalStatus: str(map.operational_status, 'Active'),
		consecutiveNegativeDays: num(map.consecutive_negative_days),
		recoveryStreakDays: num(map.recovery_streak_days),
		onboardingCompleted: map.onboarding_completed === true,
		actorType: str(map.actor_type, 'player')
	};
}
