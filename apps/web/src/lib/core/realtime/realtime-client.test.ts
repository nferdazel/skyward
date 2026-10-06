import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { RealtimeClient, type SocketLike } from './realtime-client';

class MockSocket implements SocketLike {
	sent: string[] = [];
	closed = false;
	onopen?: () => void;
	onmessage?: (event: { data: unknown }) => void;
	onerror?: (error: unknown) => void;
	onclose?: () => void;

	send(data: string): void {
		this.sent.push(data);
	}
	close(): void {
		this.closed = true;
	}
	/** Bantu test: simulasikan pesan masuk dari server. */
	receive(payload: unknown): void {
		this.onmessage?.({ data: JSON.stringify(payload) });
	}
	/** Bantu test: simulasikan koneksi terbuka (onopen). */
	open(): void {
		this.onopen?.();
	}
	drop(): void {
		this.onclose?.();
	}
}

describe('RealtimeClient', () => {
	beforeEach(() => vi.useFakeTimers());
	afterEach(() => vi.useRealTimers());

	function makeClient(overrides?: { ticket: string | null }) {
		const sockets: MockSocket[] = [];
		const ticket = overrides ? overrides.ticket : 'ticket-1';
		const client = new RealtimeClient({
			baseUrl: 'http://localhost:8090',
			ticketFetcher: async () => ticket,
			connect: () => {
				const s = new MockSocket();
				sockets.push(s);
				return s;
			}
		});
		return { client, sockets };
	}

	it('does not connect when there is no session (null ticket)', async () => {
		const { client, sockets } = makeClient({ ticket: null });
		await client.connect();
		expect(sockets).toHaveLength(0);
		expect(client.isConnected).toBe(false);
	});

	it('connects and opens the socket with the ticket in the query', async () => {
		const { client, sockets } = makeClient();
		await client.connect();
		expect(sockets).toHaveLength(1);
		expect(client.isConnected).toBe(true);
	});

	it('ref-counts channel subscriptions (AUDIT-14)', async () => {
		const { client, sockets } = makeClient();
		await client.connect();
		const sock = sockets[0];
		sock.open(); // subscriptions are only sent once the socket is open

		client.subscribe(['users']);
		client.subscribe(['users']); // kedua pemegang
		expect(sock.sent).toEqual([JSON.stringify({ action: 'subscribe', channels: ['users'] })]);

		client.unsubscribe(['users']); // satu masih pegang → tidak ada pesan
		expect(sock.sent).toHaveLength(1);

		client.unsubscribe(['users']); // habis → unsubscribe terkirim
		expect(sock.sent).toHaveLength(2);
		expect(JSON.parse(sock.sent[1])).toEqual({ action: 'unsubscribe', channels: ['users'] });
	});

	it('does not send before the socket is open (avoids CONNECTING-state error)', async () => {
		const { client, sockets } = makeClient();
		await client.connect();
		const sock = sockets[0];

		// Subscribing before onopen must be buffered, not sent.
		client.subscribe(['users']);
		expect(sock.sent).toHaveLength(0);

		sock.open(); // onopen fires → the pending channel is now subscribed
		expect(sock.sent).toEqual([JSON.stringify({ action: 'subscribe', channels: ['users'] })]);
	});

	it('delivers server events to listeners', async () => {
		const { client, sockets } = makeClient();
		const seen: unknown[] = [];
		client.onEvent((e) => seen.push(e));
		await client.connect();

		sockets[0].receive({ type: 'change', channel: 'users', event: 'world_tick' });

		expect(seen).toEqual([{ type: 'change', channel: 'users', event: 'world_tick' }]);
	});

	it('reconnects with backoff after an unexpected close', async () => {
		const { client, sockets } = makeClient();
		await client.connect();
		expect(sockets).toHaveLength(1);

		sockets[0].drop(); // koneksi putus
		expect(client.isConnected).toBe(false);

		// Backoff pertama = 2s.
		await vi.advanceTimersByTimeAsync(2000);
		expect(sockets).toHaveLength(2);
	});

	it('does not reconnect after an intentional disconnect', async () => {
		const { client, sockets } = makeClient();
		await client.connect();

		client.disconnect();
		await vi.advanceTimersByTimeAsync(60_000);

		expect(sockets).toHaveLength(1);
	});

	it('does not reset backoff until a message proves the connection is alive', async () => {
		const { client, sockets } = makeClient();
		await client.connect();
		sockets[0].drop(); // pertama: belum pernah sehat

		await vi.advanceTimersByTimeAsync(2000);
		expect(sockets).toHaveLength(2);

		// Koneksi kedua putus tanpa pernah menerima pesan → backoff naik (4s).
		sockets[1].drop();
		await vi.advanceTimersByTimeAsync(2000);
		expect(sockets).toHaveLength(2); // belum 4s

		await vi.advanceTimersByTimeAsync(2000);
		expect(sockets).toHaveLength(3); // 4s total
	});
});
