import { render, screen } from '@testing-library/svelte';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';
import AppButton from './AppButton.svelte';

describe('AppButton', () => {
	it('renders its label and calls onclick when pressed', async () => {
		const onclick = vi.fn();
		render(AppButton, { props: { text: 'Beli', onclick } });

		const button = screen.getByRole('button', { name: 'Beli' });
		await userEvent.click(button);

		expect(onclick).toHaveBeenCalledOnce();
	});

	it('is disabled while loading and does not fire onclick', async () => {
		const onclick = vi.fn();
		render(AppButton, { props: { text: 'Simpan', onclick, loading: true } });

		const button = screen.getByRole('button') as HTMLButtonElement;
		expect(button.disabled).toBe(true);
		expect(button.getAttribute('aria-busy')).toBe('true');

		await userEvent.click(button);
		expect(onclick).not.toHaveBeenCalled();
	});

	it('is disabled when no onclick handler is given', () => {
		render(AppButton, { props: { text: 'Tanpa aksi' } });
		expect((screen.getByRole('button') as HTMLButtonElement).disabled).toBe(true);
	});
});
