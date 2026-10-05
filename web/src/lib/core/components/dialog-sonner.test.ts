import { render, screen } from '@testing-library/svelte';
import { describe, expect, it, vi } from 'vitest';
import AppDialogShell from './AppDialogShell.svelte';
import { NotificationStore } from '$lib/features/notification/state/notification-store.svelte';
import SkywardSonner from './SkywardSonner.svelte';

describe('AppDialogShell', () => {
	it('renders an accessible dialog with an uppercased title', () => {
		render(AppDialogShell, {
			props: { title: 'Beli pesawat', onclose: vi.fn() }
		});
		const dialog = screen.getByRole('dialog');
		expect(dialog).toHaveAttribute('aria-modal', 'true');
		expect(screen.getByText('BELI PESAWAT')).toBeInTheDocument();
	});
});

describe('NotificationStore + SkywardSonner', () => {
	it('excludes event notifications from toasts', () => {
		const store = new NotificationStore();
		store.push({ type: 'success', title: 'Ok' });
		store.push({ type: 'event', title: 'Fuel shock' });

		expect(store.toasts.map((t) => t.title)).toEqual(['Ok']);
	});

	it('dismisses a toast by id', () => {
		const store = new NotificationStore();
		const id = store.push({ type: 'info', title: 'Hi' });
		store.dismiss(id);
		expect(store.toasts).toHaveLength(0);
	});

	it('renders toasts and removes them on click', async () => {
		const store = new NotificationStore();
		store.push({ type: 'warning', title: 'Wear tinggi' });
		const { rerender } = render(SkywardSonner, {
			props: { items: store.toasts, ondismiss: (id) => store.dismiss(id) }
		});

		const toast = screen.getByText('Wear tinggi').closest('button') as HTMLButtonElement;
		await toast.click();
		rerender({ items: store.toasts, ondismiss: (id) => store.dismiss(id) });

		expect(store.toasts).toHaveLength(0);
	});
});
