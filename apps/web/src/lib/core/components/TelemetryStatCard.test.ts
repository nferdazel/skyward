import { render, screen } from '@testing-library/svelte';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';
import TelemetryStatCard from './TelemetryStatCard.svelte';

describe('TelemetryStatCard', () => {
	it('renders label, value, unit and formatted delta', () => {
		render(TelemetryStatCard, {
			props: {
				label: 'OPERATING MARGIN',
				value: '18.4',
				unit: '%',
				delta: 3.2,
				deltaPeriod: 'vs 30d'
			}
		});

		expect(screen.getByText('OPERATING MARGIN')).toBeInTheDocument();
		expect(screen.getByText('18.4')).toBeInTheDocument();
		expect(screen.getByText('%')).toBeInTheDocument();
		expect(screen.getByText('+3.2%')).toBeInTheDocument();
		expect(screen.getByText('vs 30d')).toBeInTheDocument();
	});

	it('triggers onclick when clicked if interactive', async () => {
		const onclick = vi.fn();
		render(TelemetryStatCard, {
			props: {
				label: 'FLEET READY',
				value: '12',
				onclick
			}
		});

		const card = screen.getByRole('button');
		await userEvent.click(card);
		expect(onclick).toHaveBeenCalledOnce();
	});
});
