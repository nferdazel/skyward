import { render, screen } from '@testing-library/svelte';
import { describe, expect, it } from 'vitest';
import ExpenseBreakdownBar from './ExpenseBreakdownBar.svelte';

describe('ExpenseBreakdownBar', () => {
	it('calculates total expense and displays category breakdown', () => {
		render(ExpenseBreakdownBar, {
			props: {
				fuel: 50000,
				crew: 30000,
				maintenance: 20000
			}
		});

		expect(screen.getByText(/cost distribution/i)).toBeInTheDocument();
		expect(screen.getByText('Fuel')).toBeInTheDocument();
		expect(screen.getByText('50%')).toBeInTheDocument();
		expect(screen.getByText('Crew')).toBeInTheDocument();
		expect(screen.getByText('30%')).toBeInTheDocument();
		expect(screen.getByText('Maint')).toBeInTheDocument();
		expect(screen.getByText('20%')).toBeInTheDocument();
	});

	it('supports custom segments', () => {
		render(ExpenseBreakdownBar, {
			props: {
				segments: [
					{ label: 'Ground Ops', amount: 1000 },
					{ label: 'Catering', amount: 3000 }
				]
			}
		});

		expect(screen.getByText('Ground Ops')).toBeInTheDocument();
		expect(screen.getByText('25%')).toBeInTheDocument();
		expect(screen.getByText('Catering')).toBeInTheDocument();
		expect(screen.getByText('75%')).toBeInTheDocument();
	});
});
