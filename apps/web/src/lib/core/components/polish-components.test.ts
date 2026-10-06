import { render, screen } from '@testing-library/svelte';
import { describe, expect, it, vi } from 'vitest';
import SearchableAirportDropdown from './SearchableAirportDropdown.svelte';
import NotificationPanel from './NotificationPanel.svelte';
import { NotificationStore } from '$lib/features/notification/state/notification-store.svelte';
import type { Airport } from '$lib/features/routes/domain/airport';

const airports: Airport[] = [
	{
		iata: 'SIN',
		name: 'Changi',
		city: 'Singapore',
		country: 'SG',
		latitude: 1.36,
		longitude: 103.99,
		demandIndex: 90
	},
	{
		iata: 'KUL',
		name: 'KLIA',
		city: 'Kuala Lumpur',
		country: 'MY',
		latitude: 2.74,
		longitude: 101.7,
		demandIndex: 70
	}
];

describe('SearchableAirportDropdown', () => {
	it('filters by query and reports the selection', async () => {
		const onselect = vi.fn();
		render(SearchableAirportDropdown, { props: { airports, value: null, onselect } });

		const input = screen.getByPlaceholderText('Search IATA / city');
		await input.focus();
		await screen.getByText('KUL').click();

		expect(onselect).toHaveBeenCalledWith(airports[1]);
	});
});

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
