import { render, screen } from '@testing-library/svelte';
import { describe, expect, it } from 'vitest';
import TerminalLoader from './TerminalLoader.svelte';

describe('TerminalLoader', () => {
	it('renders system status and boot message', () => {
		render(TerminalLoader, {
			props: {
				message: 'RESTORING CEO FLIGHT OPERATIONS...',
				subMessage: 'SYNCING SATELLITE RELAY'
			}
		});

		expect(screen.getByRole('status')).toBeInTheDocument();
		expect(screen.getByText('RESTORING CEO FLIGHT OPERATIONS...')).toBeInTheDocument();
		expect(screen.getByText('SYNCING SATELLITE RELAY')).toBeInTheDocument();
		expect(screen.getByText('SYS.RDY')).toBeInTheDocument();
	});
});
