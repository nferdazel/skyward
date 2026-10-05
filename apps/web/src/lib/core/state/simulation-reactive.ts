/**
 * Helper reaktif untuk store yang perlu reload saat sinkronisasi simulasi
 * selesai. Port dari Flutter `SimulationReactiveMixin` (AUDIT-18).
 *
 * Decoupled dari store simulasi konkret: pemanggil memberi sumber status
 * sinkronisasi (`getState`). Callback dijadwalkan dengan debounce
 * trailing-edge; panggilan baru membatalkan timer lama, dan `dispose`
 * membatalkan timer yang tertunda.
 */
export interface SyncState {
	isSyncing: boolean;
	errorMessage: string | null;
}

export interface TimerApi {
	setTimeout(fn: () => void, ms: number): unknown;
	clearTimeout(handle: unknown): void;
}

const defaultTimers: TimerApi = {
	setTimeout: (fn, ms) => setTimeout(fn, ms),
	clearTimeout: (h) => clearTimeout(h as ReturnType<typeof setTimeout>)
};

export class SimulationReactive {
	private wasSyncing = false;
	private timer: unknown = null;
	private disposed = false;
	private stopListening?: () => void;

	constructor(
		private readonly getState: () => SyncState,
		private readonly onState: (listener: (state: SyncState) => void) => () => void,
		private readonly timers: TimerApi = defaultTimers
	) {}

	/**
	 * Panggil `onSyncComplete` saat sinkronisasi bertransisi true → false tanpa
	 * error, setelah `delayMs`. Delay default 0 (langsung).
	 */
	subscribeToSimulation(onSyncComplete: () => void, delayMs = 0): void {
		this.stopListening?.();
		this.wasSyncing = false;
		this.stopListening = this.onState((state) => {
			if (this.disposed) return;
			if (this.wasSyncing && !state.isSyncing && state.errorMessage === null) {
				this.schedule(onSyncComplete, delayMs);
			}
			this.wasSyncing = state.isSyncing;
		});
	}

	private schedule(callback: () => void, delayMs: number): void {
		if (this.timer !== null) this.timers.clearTimeout(this.timer);
		if (delayMs <= 0) {
			this.timer = null;
			callback();
			return;
		}
		this.timer = this.timers.setTimeout(() => {
			this.timer = null;
			if (!this.disposed) callback();
		}, delayMs);
	}

	dispose(): void {
		this.disposed = true;
		this.stopListening?.();
		this.stopListening = undefined;
		if (this.timer !== null) {
			this.timers.clearTimeout(this.timer);
			this.timer = null;
		}
	}
}
