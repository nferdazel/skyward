/** Notifikasi in-app. Port dari `GameNotification` / `NotificationType`. */
export type NotificationType = 'info' | 'success' | 'warning' | 'error' | 'event';

export interface GameNotification {
	id: string;
	type: NotificationType;
	title: string;
	message?: string;
	createdAt: number;
}

/**
 * Store notifikasi in-app (queue + toast). Port dari `NotificationCubit`.
 * World events TIDAK ditampilkan sebagai toast (status persisten, lihat sonner).
 */
export class NotificationStore {
	state = $state<{ items: GameNotification[] }>({ items: [] });

	private seq = 0;

	/** Tambah notifikasi; mengembalikan id. */
	push(input: Omit<GameNotification, 'id' | 'createdAt'>): string {
		const id = `n${++this.seq}`;
		const item: GameNotification = { ...input, id, createdAt: Date.now() };
		this.state = { items: [...this.state.items, item] };
		return id;
	}

	dismiss(id: string): void {
		this.state = { items: this.state.items.filter((n) => n.id !== id) };
	}

	clear(): void {
		this.state = { items: [] };
	}

	/** Notifikasi yang tampil sebagai toast (event dikecualikan). */
	get toasts(): GameNotification[] {
		return this.state.items.filter((n) => n.type !== 'event').slice(0, 4);
	}
}
