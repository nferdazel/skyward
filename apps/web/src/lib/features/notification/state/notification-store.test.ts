import { describe, expect, it } from 'vitest';
import { NotificationStore, type TimerApi } from './notification-store.svelte';

/** Timer palsu: merekam callback agar auto-dismiss bisa dipicu manual. */
function fakeTimers() {
	const scheduled = new Map<unknown, () => void>();
	let seq = 0;
	const timer: TimerApi = {
		setTimeout: (fn) => {
			const handle = ++seq;
			scheduled.set(handle, fn);
			return handle;
		},
		clearTimeout: (handle) => scheduled.delete(handle)
	};
	return {
		timer,
		pending: () => scheduled.size,
		fireAll: () => {
			const fns = [...scheduled.values()];
			scheduled.clear();
			for (const fn of fns) fn();
		}
	};
}

describe('NotificationStore', () => {
	it('push adds a read=false item and returns its id', () => {
		const store = new NotificationStore(fakeTimers().timer);

		const id = store.push({ type: 'info', title: 'Hello' });

		expect(id).toBe('n1');
		expect(store.state.items).toHaveLength(1);
		expect(store.state.items[0]).toMatchObject({ id: 'n1', title: 'Hello', read: false });
	});

	it('auto-dismisses non-event notifications', () => {
		const timers = fakeTimers();
		const store = new NotificationStore(timers.timer);

		store.push({ type: 'success', title: 'Done' });
		expect(timers.pending()).toBe(1);

		timers.fireAll();
		expect(store.state.items).toHaveLength(0);
	});

	it('never auto-dismisses world events', () => {
		const timers = fakeTimers();
		const store = new NotificationStore(timers.timer);

		store.push({ type: 'event', title: 'World tick' });

		expect(timers.pending()).toBe(0);
		expect(store.state.items).toHaveLength(1);
	});

	it('dismiss removes the item and its timer', () => {
		const timers = fakeTimers();
		const store = new NotificationStore(timers.timer);
		const id = store.push({ type: 'info', title: 'Hi' });

		store.dismiss(id);

		expect(store.state.items).toHaveLength(0);
		expect(timers.pending()).toBe(0);
	});

	it('clear empties items and timers', () => {
		const timers = fakeTimers();
		const store = new NotificationStore(timers.timer);
		store.push({ type: 'info', title: 'a' });
		store.push({ type: 'info', title: 'b' });

		store.clear();

		expect(store.state.items).toHaveLength(0);
		expect(timers.pending()).toBe(0);
	});

	it('unreadCount reflects read state; markAllRead zeroes it', () => {
		const store = new NotificationStore(fakeTimers().timer);
		store.push({ type: 'info', title: 'a' });
		store.push({ type: 'info', title: 'b' });
		expect(store.unreadCount).toBe(2);

		store.markAllRead();
		expect(store.unreadCount).toBe(0);
	});

	it('toasts exclude events and cap at four', () => {
		const store = new NotificationStore(fakeTimers().timer);
		store.push({ type: 'event', title: 'world' });
		for (let i = 0; i < 5; i++) store.push({ type: 'info', title: `n${i}` });

		const toasts = store.toasts;
		expect(toasts).toHaveLength(4);
		expect(toasts.every((t) => t.type !== 'event')).toBe(true);
	});
});
