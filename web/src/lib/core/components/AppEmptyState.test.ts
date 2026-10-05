import { render, screen } from '@testing-library/svelte';
import { describe, expect, it, vi } from 'vitest';
import AppEmptyState from './AppEmptyState.svelte';
import SkeletonCard from './SkeletonCard.svelte';

describe('AppEmptyState', () => {
	it('shows title and description', () => {
		render(AppEmptyState, {
			props: { title: 'Belum ada rute', description: 'Buka rute pertama.' }
		});
		expect(screen.getByText('Belum ada rute')).toBeInTheDocument();
		expect(screen.getByText('Buka rute pertama.')).toBeInTheDocument();
	});

	it('renders an action button only when a label is given', async () => {
		const onAction = vi.fn();
		const { unmount } = render(AppEmptyState, {
			props: { title: 'Kosong', description: '—', actionLabel: 'Tambah', onAction }
		});
		const button = screen.getByRole('button', { name: 'Tambah' });
		await button.click();
		expect(onAction).toHaveBeenCalledOnce();
		unmount();

		render(AppEmptyState, { props: { title: 'Kosong', description: '—' } });
		expect(screen.queryByRole('button')).toBeNull();
	});
});

describe('SkeletonCard', () => {
	it('is hidden from assistive tech', () => {
		const { container } = render(SkeletonCard, { props: {} });
		expect(container.querySelector('.skeleton-card')?.getAttribute('aria-hidden')).toBe('true');
	});
});
