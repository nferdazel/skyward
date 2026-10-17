import { render, screen } from '@testing-library/svelte';
import { describe, expect, it } from 'vitest';
import CabinLayoutPreview from './CabinLayoutPreview.svelte';

describe('CabinLayoutPreview', () => {
	it('calculates slots correctly (Economy: 1x, Business: 2x, First: 3x)', () => {
		// 10 Eco * 1 + 5 Bus * 2 + 2 First * 3 = 10 + 10 + 6 = 26 slots
		render(CabinLayoutPreview, {
			props: {
				capacity: 30,
				economy: 10,
				business: 5,
				firstClass: 2,
				tailNumber: 'PK-SKW'
			}
		});

		expect(screen.getByText('26 / 30 SLOTS')).toBeInTheDocument();
		expect(screen.getByText('PK-SKW')).toBeInTheDocument();
	});

	it('indicates overage when total slots exceed aircraft capacity', () => {
		// 20 Eco * 1 + 10 Bus * 2 = 40 slots, capacity 30 -> over by 10
		render(CabinLayoutPreview, {
			props: {
				capacity: 30,
				economy: 20,
				business: 10,
				firstClass: 0
			}
		});

		expect(screen.getByText('40 / 30 SLOTS')).toBeInTheDocument();
		expect(screen.getByText('(10 OVER)')).toBeInTheDocument();
	});
});
