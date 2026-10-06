import { render, screen } from '@testing-library/svelte';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';
import TactileButton from './TactileButton.svelte';

describe('TactileButton', () => {
	it('renders its label and calls onclick when pressed', async () => {
		const onclick = vi.fn();
		render(TactileButton, { props: { text: 'Buy', onclick } });

		await userEvent.click(screen.getByRole('button', { name: 'Buy' }));

		expect(onclick).toHaveBeenCalledOnce();
	});

	it('is disabled while loading and does not fire onclick', async () => {
		const onclick = vi.fn();
		render(TactileButton, { props: { text: 'Save', onclick, loading: true } });

		const button = screen.getByRole('button') as HTMLButtonElement;
		expect(button.disabled).toBe(true);
		expect(button.getAttribute('aria-busy')).toBe('true');

		await userEvent.click(button);
		expect(onclick).not.toHaveBeenCalled();
	});

	it('is disabled when no onclick handler is given', () => {
		render(TactileButton, { props: { text: 'No action' } });
		expect((screen.getByRole('button') as HTMLButtonElement).disabled).toBe(true);
	});
});
