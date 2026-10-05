import { render, screen } from '@testing-library/svelte';
import { describe, expect, it } from 'vitest';
import AppBadge from './AppBadge.svelte';

describe('AppBadge', () => {
	it('uppercases the label', () => {
		render(AppBadge, { props: { label: 'Active', tone: 'success' } });
		expect(screen.getByRole('status')).toHaveTextContent('ACTIVE');
	});

	it('marks the semantic tone on the element', () => {
		const { container } = render(AppBadge, { props: { label: 'Late', tone: 'error' } });
		expect(container.querySelector('.app-badge')?.classList.contains('error')).toBe(true);
	});
});
