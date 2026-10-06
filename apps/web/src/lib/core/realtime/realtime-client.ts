import type { RealtimeEvent, TimerApi } from './ws-types';

/** Koneksi WebSocket minimal yang dibutuhkan klien (dapat di-mock di test). */
export interface SocketLike {
	send(data: string): void;
	close(): void;
	onopen?: () => void;
	onmessage?: (event: { data: unknown }) => void;
	onerror?: (error: unknown) => void;
	onclose?: () => void;
}

export interface RealtimeOptions {
	baseUrl: string;
	/** Tukar sesi aktif menjadi tiket sekali pakai. null = belum ada sesi. */
	ticketFetcher: () => Promise<string | null>;
	/** Buat koneksi. Default memakai WebSocket global; test menyuntik mock. */
	connect?: (url: string) => SocketLike;
	timers?: TimerApi;
	/** Interval ping (ms). Default 30s. */
	pingIntervalMs?: number;
	/** Batas backoff (ms). Default 30s. */
	maxReconnectDelayMs?: number;
}

const defaultTimers: TimerApi = {
	setTimeout: (fn, ms) => setTimeout(fn, ms),
	clearTimeout: (h) => clearTimeout(h as ReturnType<typeof setTimeout>),
	setInterval: (fn, ms) => setInterval(fn, ms),
	clearInterval: (h) => clearInterval(h as ReturnType<typeof setInterval>)
};

/**
 * WebSocket client ke skyward-api (Go hub). Port dari Flutter `GoRealtimeClient`.
 *
 * Handshake memakai tiket sekali pakai (`POST /ws/ticket`), bukan JWT di query
 * (D3): browser tidak bisa memasang header pada handshake WebSocket.
 *
 * - Satu koneksi dipakai bersama semua store.
 * - Subscribe channel memakai ref count (AUDIT-14): pesan ke server hanya
 *   dikirim saat ref count 0→1 / 1→0.
 * - Reconnect backoff eksponensial 2s → 30s; backoff hanya di-reset setelah
 *   koneksi terbukti hidup (pesan pertama diterima).
 *
 * Semua timer lewat `timers` sehingga test bisa memakai fake timer (memperbaiki
 * utang Flutter: 6 test realtime yang menunggu wall-clock 2.5–8 dtk).
 */
export class RealtimeClient {
	private readonly baseUrl: string;
	private readonly ticketFetcher: () => Promise<string | null>;
	private readonly connectFn: (url: string) => SocketLike;
	private readonly timers: TimerApi;
	private readonly pingIntervalMs: number;
	private readonly maxReconnectDelayMs: number;

	private socket: SocketLike | null = null;
	private readonly channelRefs = new Map<string, number>();
	private pingTimer: unknown = null;
	private reconnectTimer: unknown = null;
	private reconnectAttempts = 0;
	private intentionalDisconnect = false;
	private generation = 0;
	private reconnectScheduledForGeneration = -1;
	private connectionHealthy = false;
	/** True only once the socket's onopen has fired (guards send() calls). */
	private socketOpen = false;

	private readonly listeners = new Set<(event: RealtimeEvent) => void>();

	constructor(opts: RealtimeOptions) {
		this.baseUrl = opts.baseUrl;
		this.ticketFetcher = opts.ticketFetcher;
		this.connectFn =
			opts.connect ??
			((url) => {
				const ws = new WebSocket(url);
				const adapter: SocketLike = {
					send: (d) => ws.send(d),
					close: () => ws.close()
				};
				ws.onopen = () => adapter.onopen?.();
				ws.onmessage = (ev: MessageEvent) => adapter.onmessage?.({ data: ev.data });
				ws.onerror = () => adapter.onerror?.(new Error('websocket error'));
				ws.onclose = () => adapter.onclose?.();
				return adapter;
			});
		this.timers = opts.timers ?? defaultTimers;
		this.pingIntervalMs = opts.pingIntervalMs ?? 30_000;
		this.maxReconnectDelayMs = opts.maxReconnectDelayMs ?? 30_000;
	}

	/** Daftarkan listener event. Mengembalikan fungsi untuk melepas. */
	onEvent(listener: (event: RealtimeEvent) => void): () => void {
		this.listeners.add(listener);
		return () => this.listeners.delete(listener);
	}

	get isConnected(): boolean {
		return this.socket !== null;
	}

	async connect(): Promise<void> {
		if (this.socket !== null) return;
		this.intentionalDisconnect = false;
		if (this.reconnectTimer !== null) {
			this.timers.clearTimeout(this.reconnectTimer);
			this.reconnectTimer = null;
		}
		const generation = ++this.generation;

		let ticket: string | null;
		try {
			ticket = await this.ticketFetcher();
		} catch {
			if (generation === this.generation) this.scheduleReconnect();
			return;
		}
		if (generation !== this.generation || this.intentionalDisconnect) return;
		if (!ticket) return; // tanpa sesi, jangan reconnect.

		const wsScheme = this.baseUrl.startsWith('https') ? 'wss' : 'ws';
		const cleanBase = this.baseUrl.replace(/^https?:\/\//, '').replace(/\/$/, '');
		const url = `${wsScheme}://${cleanBase}/ws?ticket=${encodeURIComponent(ticket)}`;

		let socket: SocketLike;
		try {
			socket = this.connectFn(url);
		} catch {
			if (generation === this.generation) {
				this.teardown();
				this.scheduleReconnect();
			}
			return;
		}

		if (generation !== this.generation || this.intentionalDisconnect) {
			socket.close();
			return;
		}

		this.socket = socket;
		this.connectionHealthy = false;
		this.socketOpen = false;
		this.reconnectScheduledForGeneration = -1;

		socket.onopen = () => {
			if (generation !== this.generation) return;
			this.socketOpen = true;
			// Subscribe channel aktif begitu koneksi benar-benar terbuka
			// (mengirim sebelum open memicu "Still in CONNECTING state").
			if (this.channelRefs.size > 0) {
				this.sendChannels([...this.channelRefs.keys()], 'subscribe');
			}
		};
		socket.onmessage = (event) => this.onMessage(event.data, generation);
		socket.onerror = () => this.onError(generation);
		socket.onclose = () => this.onDone(generation);

		this.pingTimer = this.timers.setInterval(() => this.ping(), this.pingIntervalMs);
	}

	subscribe(channels: string[]): void {
		const fresh: string[] = [];
		for (const ch of channels) {
			const n = (this.channelRefs.get(ch) ?? 0) + 1;
			this.channelRefs.set(ch, n);
			if (n === 1) fresh.push(ch);
		}
		this.sendChannels(fresh, 'subscribe');
	}

	unsubscribe(channels: string[]): void {
		const gone: string[] = [];
		for (const ch of channels) {
			const n = (this.channelRefs.get(ch) ?? 1) - 1;
			if (n <= 0) {
				this.channelRefs.delete(ch);
				gone.push(ch);
			} else {
				this.channelRefs.set(ch, n);
			}
		}
		this.sendChannels(gone, 'unsubscribe');
	}

	ping(): void {
		if (!this.socketOpen) return;
		this.socket?.send(JSON.stringify({ action: 'ping' }));
	}

	disconnect(): void {
		this.intentionalDisconnect = true;
		this.generation++;
		if (this.reconnectTimer !== null) {
			this.timers.clearTimeout(this.reconnectTimer);
			this.reconnectTimer = null;
		}
		this.clearPing();
		this.socket?.close();
		this.socket = null;
		this.connectionHealthy = false;
		this.socketOpen = false;
	}

	dispose(): void {
		this.disconnect();
		this.listeners.clear();
	}

	private sendChannels(channels: string[], action: 'subscribe' | 'unsubscribe'): void {
		if (!this.socketOpen || this.socket === null || channels.length === 0) return;
		this.socket.send(JSON.stringify({ action, channels }));
	}

	private scheduleReconnect(generation?: number): void {
		if (this.intentionalDisconnect) return;
		if (generation !== undefined) {
			if (this.reconnectScheduledForGeneration === generation) return;
			this.reconnectScheduledForGeneration = generation;
		}
		if (this.reconnectTimer !== null) this.timers.clearTimeout(this.reconnectTimer);
		const seconds = Math.min(2 << this.reconnectAttempts, this.maxReconnectDelayMs / 1000);
		const delay = Math.max(seconds, 2) * 1000;
		if (this.reconnectAttempts < 30) this.reconnectAttempts++;
		this.reconnectTimer = this.timers.setTimeout(() => {
			if (!this.intentionalDisconnect) void this.connect();
		}, delay);
	}

	private clearPing(): void {
		if (this.pingTimer !== null) {
			this.timers.clearInterval(this.pingTimer);
			this.pingTimer = null;
		}
	}

	/** Bersihkan resource koneksi tanpa menandai intentional (agar reconnect). */
	private teardown(): void {
		this.clearPing();
		this.socket?.close();
		this.socket = null;
		this.socketOpen = false;
	}

	private onMessage(data: unknown, generation: number): void {
		if (generation !== this.generation) return;
		if (!this.connectionHealthy) {
			this.connectionHealthy = true;
			this.reconnectAttempts = 0;
		}
		try {
			const text = typeof data === 'string' ? data : null;
			if (text === null) return;
			const decoded = JSON.parse(text) as unknown;
			if (decoded && typeof decoded === 'object') {
				this.emit(decoded as RealtimeEvent);
			}
		} catch {
			/* pesan tidak valid diabaikan */
		}
	}

	private emit(event: RealtimeEvent): void {
		for (const listener of this.listeners) listener(event);
	}

	private onError(generation: number): void {
		if (generation !== this.generation) return;
		this.teardown();
		this.scheduleReconnect(generation);
	}

	private onDone(generation: number): void {
		if (generation !== this.generation) return;
		this.teardown();
		this.scheduleReconnect(generation);
	}
}
