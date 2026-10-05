import { describe, expect, it, vi } from 'vitest';
import { RealtimeSubscription } from './realtime-subscription';
import type { RealtimeClient } from './realtime-client';
import type { RealtimeEvent } from './ws-types';

/** Client palsu yang mencatat subscribe/unsubscribe dan bisa memancarkan event. */
function makeFakeClient() {
	const listeners = new Set<(e: RealtimeEvent) => void>();
	const calls: Array<{ action: 'subscribe' | 'unsubscribe'; channels: string[] }> = [];
	const connect = vi.fn(async () => {});
	const client = {
		connect,
		subscribe: (channels: string[]) => calls.push({ action: 'subscribe', channels }),
		unsubscribe: (channels: string[]) => calls.push({ action: 'unsubscribe', channels }),
		onEvent: (l: (e: RealtimeEvent) => void) => {
			listeners.add(l);
			return () => listeners.delete(l);
		}
	} as unknown as RealtimeClient;
	const emit = (event: RealtimeEvent) => {
		for (const l of listeners) l(event);
	};
	return { client, calls, connect, emit };
}

describe('RealtimeSubscription', () => {
	it('sends only the delta on re-subscribe (AUDIT-14)', () => {
		const { client, calls } = makeFakeClient();
		const sub = new RealtimeSubscription(client);

		sub.subscribe(['users', 'loans'], () => {});
		sub.subscribe(['users', 'fleet_aircraft'], () => {});

		expect(calls[0]).toEqual({ action: 'subscribe', channels: ['users', 'loans'] });
		// Hanya delta: tambah fleet_aircraft, lepas loans. `users` tak disentuh.
		expect(calls[1]).toEqual({ action: 'subscribe', channels: ['fleet_aircraft'] });
		expect(calls[2]).toEqual({ action: 'unsubscribe', channels: ['loans'] });
	});

	it('delivers only events on subscribed channels of type change', () => {
		const { client, emit } = makeFakeClient();
		const sub = new RealtimeSubscription(client);
		const seen: string[] = [];
		sub.subscribe(['users'], (e) => seen.push(e.channel ?? ''));

		emit({ type: 'pong' });
		emit({ type: 'change', channel: 'loans' });
		emit({ type: 'change', channel: 'users' });

		expect(seen).toEqual(['users']);
	});

	it('unsubscribes all channels on dispose', () => {
		const { client, calls } = makeFakeClient();
		const sub = new RealtimeSubscription(client);
		sub.subscribe(['users'], () => {});
		sub.dispose();

		expect(calls.at(-1)).toEqual({ action: 'unsubscribe', channels: ['users'] });
	});
});
