import type { RealtimeClient } from './realtime-client';
import type { RealtimeEvent } from './ws-types';

/**
 * Langganan realtime untuk satu store. Port dari Flutter `GoRealtimeMixin`.
 *
 * Satu koneksi WS dibagi semua store. `subscribeToRealtime` mengirim **hanya
 * delta** channel (tambah/kurang), sehingga store yang berlangganan ulang tidak
 * menambah ref count dua kali dari dirinya sendiri (AUDIT-14).
 *
 * Event realtime adalah lapisan kesegaran: handler biasanya memicu refetch REST,
 * bukan menulis state domain.
 */
export class RealtimeSubscription {
	private channels = new Set<string>();
	private off?: () => void;
	private disposed = false;

	constructor(private readonly client: RealtimeClient) {}

	/**
	 * Langganan ke daftar channel. Mengganti (bukan menambah) set channel lama:
	 * channel yang tidak lagi diminta akan di-unsubscribe.
	 */
	subscribe(channels: string[], onEvent: (event: RealtimeEvent) => void): void {
		if (this.disposed) return;
		const desired = new Set(channels);
		const toAdd = [...desired].filter((c) => !this.channels.has(c));
		const toRemove = [...this.channels].filter((c) => !desired.has(c));
		this.channels = desired;

		this.off?.();
		this.off = this.client.onEvent((event) => {
			if (event.type !== 'change') return;
			if (!event.channel || !this.channels.has(event.channel)) return;
			onEvent(event);
		});

		// Pastikan koneksi terbuka sebelum subscribe (pesan hanya terkirim bila
		// socket sudah ada).
		void this.client.connect();
		if (toAdd.length > 0) this.client.subscribe(toAdd);
		if (toRemove.length > 0) this.client.unsubscribe(toRemove);
	}

	/** Panggil dari teardown store. */
	dispose(): void {
		if (this.disposed) return;
		this.disposed = true;
		this.off?.();
		this.off = undefined;
		if (this.channels.size > 0) {
			this.client.unsubscribe([...this.channels]);
			this.channels.clear();
		}
	}
}
