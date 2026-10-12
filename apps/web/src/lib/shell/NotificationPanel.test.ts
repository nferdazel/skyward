import { render, screen } from '@testing-library/svelte';
import { describe, expect, it, vi } from 'vitest';
import NotificationPanel from './NotificationPanel.svelte';
import { NotificationStore } from '$lib/features/notification/state/notification-store.svelte';

describe('NotificationPanel', () => {
	it('lists notifications and clears them', async () => {
		const store = new NotificationStore();
		store.push({ type: 'warning', title: 'Low cash' });
		render(NotificationPanel, { props: { store, onclose: vi.fn() } });

		expect(screen.getByText('Low cash')).toBeInTheDocument();
		await screen.getByRole('button', { name: 'Clear all' }).click();
		expect(store.state.items).toHaveLength(0);
	});
});
