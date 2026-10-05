import { userFromMap, type AppUser } from '$lib/features/auth/domain/user';
import type { SimulationGateway } from '../data/simulation-gateway';
import { GameConstants, STATUS_ACTIVE } from '$lib/core/constants/game-constants';
import { SyncCoordinator } from '$lib/core/sync/sync-coordinator';
import { seasonClockTick } from '$lib/core/sync/domain-events';
import { RealtimeSubscription } from '$lib/core/realtime/realtime-subscription';
import type { RealtimeClient } from '$lib/core/realtime/realtime-client';

export interface SimulationState {
	gameTime: string;
	cashBalance: number;
	fuelPricePerLiter: number;
	gameSpeedMultiplier: number;
	isSyncing: boolean;
	lastFlightsRun: number;
	lastElapsedDays: number;
	lastRevenue: number;
	lastExpense: number;
	operationalStatus: string;
	consecutiveNegativeDays: number;
	recoveryStreakDays: number;
	bankruptcyCashThreshold: number;
	bankruptcyNegativeDaysThreshold: number;
	ticketBaseFare: number;
	ticketPerKmRate: number;
	lastUnlockedAchievements: Record<string, unknown>[];
	errorMessage: string | null;
}

export interface SimulationDeps {
	gateway: SimulationGateway;
	realtime: RealtimeClient;
	sync: SyncCoordinator;
	now?: () => number;
}

export interface SyncStateSnapshot {
	isSyncing: boolean;
	errorMessage: string | null;
}

function initial(gameTime: string, cash: number): SimulationState {
	return {
		gameTime,
		cashBalance: cash,
		fuelPricePerLiter: GameConstants.fuelPricePerLiter,
		gameSpeedMultiplier: GameConstants.defaultGameSpeedMultiplier,
		isSyncing: false,
		lastFlightsRun: 0,
		lastElapsedDays: 0,
		lastRevenue: 0,
		lastExpense: 0,
		operationalStatus: STATUS_ACTIVE,
		consecutiveNegativeDays: 0,
		recoveryStreakDays: 0,
		bankruptcyCashThreshold: GameConstants.bankruptcyCashThreshold,
		bankruptcyNegativeDaysThreshold: GameConstants.bankruptcyNegativeDaysThreshold,
		ticketBaseFare: GameConstants.ticketBaseFare,
		ticketPerKmRate: GameConstants.ticketPerKmRate,
		lastUnlockedAchievements: [],
		errorMessage: null
	};
}

function toNum(value: unknown, fallback: number): number {
	return typeof value === 'number' && Number.isFinite(value) ? value : fallback;
}

/**
 * Ratakan respons `/game-config` (daftar `{key, value}`) menjadi peta
 * `key → value`. Nilai bisa skalar JSON atau string; string numerik diubah ke
 * angka. Peta datar tanpa `key` digabung apa adanya (defensif). Port dari
 * `SimulationCubit._flattenGameConfig`.
 */
export function flattenGameConfig(entries: unknown[]): Record<string, unknown> {
	const flat: Record<string, unknown> = {};
	for (const entry of entries) {
		if (!entry || typeof entry !== 'object') continue;
		const map = entry as Record<string, unknown>;
		const key = map.key?.toString();
		if (!key) {
			for (const [k, v] of Object.entries(map)) {
				if (k === 'category' || k === 'unit' || k === 'description') continue;
				flat[k] = typeof v === 'string' && v.trim() !== '' && !isNaN(Number(v)) ? Number(v) : v;
			}
			continue;
		}
		let value = map.value;
		if (typeof value === 'string' && value.trim() !== '' && !isNaN(Number(value))) {
			value = Number(value);
		}
		flat[key] = value;
	}
	return flat;
}

/**
 * Store simulasi — sumber rekonsiliasi pusat. Port dari `SimulationCubit`.
 *
 * Semua store lain bergantung pada transisi `isSyncing` true→false (dan event
 * `season_clock_tick`) untuk memuat ulang irisan datanya.
 */
export class SimulationStore {
	state = $state<SimulationState>(initial(new Date().toISOString(), 0));

	private currentUserId: string | null = null;
	private loopRunning = false;
	private syncTimer: ReturnType<typeof setInterval> | null = null;
	private retryTimer: ReturnType<typeof setTimeout> | null = null;
	private retryCount = 0;
	private readonly maxRetries = 5;
	private realtimeSub: RealtimeSubscription;
	private realtimeSyncDebounce: ReturnType<typeof setTimeout> | null = null;
	private balanceDebounce: ReturnType<typeof setTimeout> | null = null;

	private cachedSettings: Record<string, unknown> | null = null;
	private cachedSettingsAt = 0;

	constructor(private readonly deps: SimulationDeps) {
		this.realtimeSub = new RealtimeSubscription(deps.realtime);
	}

	get isSyncing(): boolean {
		return this.state.isSyncing;
	}

	private readonly syncStateListeners = new Set<(state: SyncStateSnapshot) => void>();

	/** Berlangganan perubahan status sinkronisasi (transisi true↔false). */
	onSyncState(listener: (state: SyncStateSnapshot) => void): () => void {
		this.syncStateListeners.add(listener);
		return () => this.syncStateListeners.delete(listener);
	}

	private notifySyncState(): void {
		const snapshot: SyncStateSnapshot = {
			isSyncing: this.state.isSyncing,
			errorMessage: this.state.errorMessage
		};
		for (const listener of this.syncStateListeners) listener(snapshot);
	}

	/** Harga tiket dasar server untuk sebuah jarak (satu tempat untuk formula). */
	baseTicketPrice(distanceKm: number): number {
		return this.state.ticketBaseFare + distanceKm * this.state.ticketPerKmRate;
	}

	startLoop(input: {
		userId: string;
		initialGameTime: string;
		initialCash: number;
		initialOperationalStatus?: string;
		initialConsecutiveNegativeDays?: number;
		initialRecoveryStreakDays?: number;
	}): void {
		this.beginSession(input);
		void this.syncWithDatabase();
		this.setupRealtime();
		this.startTimers();
	}

	/** Set sesi tanpa auto-sync/loop — seam test supaya tidak ada sync in-flight. */
	beginSession(input: {
		userId: string;
		initialGameTime: string;
		initialCash: number;
		initialOperationalStatus?: string;
		initialConsecutiveNegativeDays?: number;
		initialRecoveryStreakDays?: number;
	}): void {
		this.currentUserId = input.userId;
		this.stopLoop();
		this.loopRunning = true;
		this.retryCount = 0;

		const base = initial(input.initialGameTime, input.initialCash);
		this.state = {
			...base,
			operationalStatus: input.initialOperationalStatus ?? STATUS_ACTIVE,
			consecutiveNegativeDays: input.initialConsecutiveNegativeDays ?? 0,
			recoveryStreakDays: input.initialRecoveryStreakDays ?? 0
		};
	}

	stopLoop(): void {
		this.loopRunning = false;
		if (this.syncTimer !== null) {
			clearInterval(this.syncTimer);
			this.syncTimer = null;
		}
		if (this.retryTimer !== null) {
			clearTimeout(this.retryTimer);
			this.retryTimer = null;
		}
		if (this.realtimeSyncDebounce !== null) {
			clearTimeout(this.realtimeSyncDebounce);
			this.realtimeSyncDebounce = null;
		}
		if (this.balanceDebounce !== null) {
			clearTimeout(this.balanceDebounce);
			this.balanceDebounce = null;
		}
	}

	dispose(): void {
		this.stopLoop();
		this.realtimeSub.dispose();
		this.cachedSettings = null;
		this.cachedSettingsAt = 0;
	}

	private startTimers(): void {
		if (this.syncTimer !== null) clearInterval(this.syncTimer);
		this.syncTimer = setInterval(
			() => void this.syncWithDatabase(),
			GameConstants.dbSyncIntervalMs
		);
	}

	private setupRealtime(): void {
		this.realtimeSub.subscribe(['users', 'bank_transactions'], (event) => {
			if (event.channel === 'users') this.scheduleRealtimeSync();
			else if (event.channel === 'bank_transactions') this.scheduleBalanceRefresh();
		});
	}

	private scheduleRealtimeSync(): void {
		if (this.realtimeSyncDebounce !== null) clearTimeout(this.realtimeSyncDebounce);
		this.realtimeSyncDebounce = setTimeout(() => {
			if (this.loopRunning) void this.syncWithDatabase();
		}, 400);
	}

	private scheduleBalanceRefresh(): void {
		if (this.balanceDebounce !== null) clearTimeout(this.balanceDebounce);
		this.balanceDebounce = setTimeout(() => {
			void (async () => {
				try {
					const balance = await this.deps.gateway.getUserBalance();
					this.state = { ...this.state, cashBalance: balance };
				} catch {
					/* jejak minimal: saldo akan diperbarui pada sync berikutnya */
				}
			})();
		}, 300);
	}

	async syncWithDatabase(): Promise<AppUser | null> {
		const userId = this.currentUserId;
		if (userId === null) return null;

		this.state = { ...this.state, isSyncing: true };
		this.notifySyncState();

		try {
			const [deltaRaw, profile] = await Promise.all([
				this.deps.gateway.processSimulationDelta(),
				this.deps.gateway.loadUserProfile()
			]);

			const bankBalance = toNum(profile.cash, toNum(profile.balance, this.state.cashBalance));

			let elapsedGameDays = 0;
			let flightsRun = 0;
			let lastRevenue = 0;
			let lastExpense = 0;
			let unlocked: Record<string, unknown>[] = [];

			if (deltaRaw.length > 0 && deltaRaw[0] && typeof deltaRaw[0] === 'object') {
				const result = deltaRaw[0] as Record<string, unknown>;
				elapsedGameDays = toNum(result.elapsed_game_days, 0);
				flightsRun = toNum(result.flights_run, 0);
				lastRevenue = toNum(result.revenue, 0);
				lastExpense = toNum(result.expense, 0);
				const raw = result.newly_unlocked_achievements;
				if (Array.isArray(raw)) {
					unlocked = raw
						.filter((m): m is Record<string, unknown> => !!m && typeof m === 'object')
						.map((m) => ({ ...m }));
				}
			}

			const authoritativeUser = userFromMap(profile);
			const settings = await this.loadSettings();

			// Abaikan kalau user berganti selagi sync in-flight.
			if (userId !== this.currentUserId) return null;
			this.retryCount = 0;

			this.state = {
				...this.state,
				gameTime: authoritativeUser.gameCurrentTime,
				cashBalance: bankBalance,
				fuelPricePerLiter: toNum(settings.fuel_price_per_liter, GameConstants.fuelPricePerLiter),
				gameSpeedMultiplier: toNum(
					settings.time_scale_multiplier,
					GameConstants.defaultGameSpeedMultiplier
				),
				isSyncing: false,
				errorMessage: null,
				lastElapsedDays: elapsedGameDays,
				lastFlightsRun: flightsRun,
				lastRevenue,
				lastExpense,
				lastUnlockedAchievements: unlocked,
				operationalStatus: authoritativeUser.operationalStatus,
				consecutiveNegativeDays: authoritativeUser.consecutiveNegativeDays,
				recoveryStreakDays: authoritativeUser.recoveryStreakDays,
				bankruptcyCashThreshold: toNum(
					settings.bankruptcy_cash_threshold,
					GameConstants.bankruptcyCashThreshold
				),
				bankruptcyNegativeDaysThreshold: Math.trunc(
					toNum(
						settings.bankruptcy_negative_days_threshold,
						GameConstants.bankruptcyNegativeDaysThreshold
					)
				),
				ticketBaseFare: toNum(settings.ticket_base_fare, GameConstants.ticketBaseFare),
				ticketPerKmRate: toNum(settings.ticket_per_km_rate, GameConstants.ticketPerKmRate)
			};

			const tickMs = Date.parse(authoritativeUser.gameCurrentTime);
			this.deps.sync.publish(seasonClockTick({ currentTick: Number.isNaN(tickMs) ? 0 : tickMs }));
			this.notifySyncState();

			return authoritativeUser;
		} catch (err) {
			if (userId !== this.currentUserId) return null;
			const message = err instanceof Error ? err.message : String(err);
			if (message.toLowerCase().includes('unauthorized')) {
				this.state = {
					...this.state,
					isSyncing: false,
					errorMessage: 'Session expired. Please sign in again.'
				};
				this.notifySyncState();
				return null;
			}
			this.state = { ...this.state, isSyncing: false, errorMessage: message };
			this.notifySyncState();
			this.retrySync();
			return null;
		}
	}

	/** Ambil game_config dengan cache TTL 5 menit. Kegagalan tidak fatal. */
	private async loadSettings(): Promise<Record<string, unknown>> {
		const now = this.deps.now?.() ?? Date.now();
		if (this.cachedSettings && now - this.cachedSettingsAt < GameConstants.settingsCacheTtlMs) {
			return this.cachedSettings;
		}
		try {
			const entries = await this.deps.gateway.loadGameSettings();
			if (entries.length > 0) {
				this.cachedSettings = flattenGameConfig(entries);
				this.cachedSettingsAt = now;
			}
		} catch {
			/* fallback: pakai cache lama atau konstanta */
		}
		return this.cachedSettings ?? {};
	}

	private retrySync(): void {
		if (this.retryCount >= this.maxRetries) return;
		this.retryCount += 1;
		const delayMs = this.retryCount * 2000;
		if (this.retryTimer !== null) clearTimeout(this.retryTimer);
		this.retryTimer = setTimeout(() => {
			if (this.loopRunning) void this.syncWithDatabase();
		}, delayMs);
	}

	/** Terapkan update user dari luar (realtime) tanpa mengubah payload digest. */
	applyBackendUserUpdate(updatedUser: AppUser): void {
		this.state = {
			...this.state,
			gameTime: updatedUser.gameCurrentTime,
			isSyncing: false,
			errorMessage: null,
			operationalStatus: updatedUser.operationalStatus,
			consecutiveNegativeDays: updatedUser.consecutiveNegativeDays,
			recoveryStreakDays: updatedUser.recoveryStreakDays,
			lastElapsedDays: 0,
			lastFlightsRun: 0,
			lastRevenue: 0,
			lastExpense: 0,
			lastUnlockedAchievements: []
		};
	}

	markOnboardingComplete(): Promise<void> {
		return this.deps.gateway.markOnboardingComplete();
	}
}
