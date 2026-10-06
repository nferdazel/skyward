import { render, screen } from '@testing-library/svelte';
import { describe, expect, it, vi } from 'vitest';
import WhileAwayDigest from './WhileAwayDigest.svelte';
import { NotificationStore } from '$lib/features/notification/state/notification-store.svelte';

describe('WhileAwayDigest', () => {
	it('shows elapsed days, flights and net', () => {
		render(WhileAwayDigest, {
			props: { elapsedDays: 2.5, flightsRun: 12, revenue: 5000, expense: 2000, onclose: vi.fn() }
		});
		expect(screen.getByText('2.5 game days elapsed.')).toBeInTheDocument();
		expect(screen.getByText('12')).toBeInTheDocument();
		expect(screen.getByText('$5,000')).toBeInTheDocument();
		expect(screen.getByText('$3,000')).toBeInTheDocument(); // net
	});
});

describe('NotificationStore read-state', () => {
	it('counts unread and clears them on markAllRead', () => {
		const store = new NotificationStore();
		store.push({ type: 'info', title: 'A' });
		store.push({ type: 'warning', title: 'B' });
		expect(store.unreadCount).toBe(2);

		store.markAllRead();
		expect(store.unreadCount).toBe(0);
		expect(store.state.items).toHaveLength(2);
	});
});
