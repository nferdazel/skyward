/** In-app notification. Ported from `GameNotification` / `NotificationType`. */
export type NotificationType = 'info' | 'success' | 'warning' | 'error' | 'event';

export interface GameNotification {
	id: string;
	type: NotificationType;
	title: string;
	message?: string;
	createdAt: number;
	read?: boolean;
}

export interface TimerApi {
	setTimeout(fn: () => void, ms: number): unknown;
	clearTimeout(handle: unknown): void;
}

const defaultTimers: TimerApi = {
	setTimeout: (fn, ms) => setTimeout(fn, ms),
	clearTimeout: (h) => clearTimeout(h as ReturnType<typeof setTimeout>)
};

/** How long a toast stays before auto-dismissing (ms). */
const AUTO_DISMISS_MS = 6000;

/**
 * In-app notification store (queue + toast). Ported from `NotificationCubit`.
 * World events are NOT shown as toasts (persistent status instead).
 *
 * Toasts auto-dismiss after `AUTO_DISMISS_MS`; otherwise an achievement toast
 * would pile up permanently in the corner (it has no other trigger to clear).
 */
export class NotificationStore {
	state = $state<{ items: GameNotification[] }>({ items: [] });

	private seq = 0;
	private readonly timers: Map<string, unknown> = new Map();

	constructor(private readonly timer: TimerApi = defaultTimers) {}

	/** Add a notification; returns its id. */
	push(input: Omit<GameNotification, 'id' | 'createdAt'>): string {
		const id = `n${++this.seq}`;
		const item: GameNotification = { ...input, id, createdAt: Date.now(), read: false };
		this.state = { items: [...this.state.items, item] };
		// Events are persistent status (shown elsewhere), so they do not toast
		// and do not auto-dismiss; everything else clears itself.
		if (item.type !== 'event') {
			const handle = this.timer.setTimeout(() => this.dismiss(id), AUTO_DISMISS_MS);
			this.timers.set(id, handle);
		}
		return id;
	}

	dismiss(id: string): void {
		const handle = this.timers.get(id);
		if (handle !== undefined) {
			this.timer.clearTimeout(handle);
			this.timers.delete(id);
		}
		this.state = { items: this.state.items.filter((n) => n.id !== id) };
	}

	clear(): void {
		for (const handle of this.timers.values()) this.timer.clearTimeout(handle);
		this.timers.clear();
		this.state = { items: [] };
	}

	/** Number of unread notifications. */
	get unreadCount(): number {
		return this.state.items.filter((n) => !n.read).length;
	}

	/** Mark everything read (called when the panel opens). */
	markAllRead(): void {
		this.state = { items: this.state.items.map((n) => ({ ...n, read: true })) };
	}

	/** Notifications shown as toasts (events excluded). */
	get toasts(): GameNotification[] {
		return this.state.items.filter((n) => n.type !== 'event').slice(0, 4);
	}
}
