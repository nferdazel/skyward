import { render, screen, within } from '@testing-library/svelte';
import userEvent from '@testing-library/user-event';
import { beforeEach, describe, expect, it, vi } from 'vitest';
import LoginPage from './+page.svelte';

const mocks = vi.hoisted(() => ({
	auth: {
		login: vi.fn(),
		register: vi.fn(),
		resetPassword: vi.fn(),
		error: null as string | null
	}
}));

vi.mock('$lib/features/auth/state/auth-context.svelte', () => ({
	getAuthStore: () => mocks.auth
}));

/** Tombol submit di dalam form — tab "Sign in"/"Register" bernama sama. */
function submitButton(name: string): HTMLButtonElement {
	const form = document.querySelector('form');
	if (!form) throw new Error('form login tidak ada');
	return within(form).getByRole('button', { name }) as HTMLButtonElement;
}

beforeEach(() => {
	vi.clearAllMocks();
	mocks.auth.error = null;
	mocks.auth.resetPassword.mockResolvedValue(true);
});

describe('halaman login — gerbang daftar', () => {
	it('menolak password di bawah 6 karakter, sesuai aturan server', async () => {
		render(LoginPage);
		await userEvent.click(screen.getByRole('tab', { name: 'Register' }));

		await userEvent.type(screen.getByLabelText('Username'), 'pilot');
		await userEvent.type(screen.getByLabelText('Password'), '12345');
		await userEvent.type(screen.getByLabelText('Company name'), 'Skyward Air');
		await userEvent.type(screen.getByLabelText('CEO name'), 'Sachiel');
		expect(submitButton('Register').disabled).toBe(true);

		await userEvent.type(screen.getByLabelText('Password'), '6');
		expect(submitButton('Register').disabled).toBe(false);
	});

	it('tidak memblokir login dengan password pendek (biar server yang menilai)', async () => {
		render(LoginPage);
		await userEvent.type(screen.getByLabelText('Username'), 'pilot');
		await userEvent.type(screen.getByLabelText('Password'), '123');
		expect(submitButton('Sign in').disabled).toBe(false);
	});
});

describe('halaman login — dialog reset password', () => {
	async function openReset() {
		render(LoginPage);
		await userEvent.click(screen.getByRole('button', { name: 'Forgot password?' }));
		return screen.getByRole('dialog');
	}

	it('baru bisa submit setelah konfirmasi cocok', async () => {
		const dialog = await openReset();
		const submit = within(dialog).getByRole('button', {
			name: 'Reset password'
		}) as HTMLButtonElement;

		await userEvent.type(within(dialog).getByLabelText('Username'), 'pilot');
		await userEvent.type(within(dialog).getByLabelText('New password'), 'newpass123');
		expect(submit.disabled).toBe(true);

		await userEvent.type(within(dialog).getByLabelText('Confirm new password'), 'newpass12');
		expect(submit.disabled).toBe(true);

		await userEvent.type(within(dialog).getByLabelText('Confirm new password'), '3');
		expect(submit.disabled).toBe(false);
	});

	it('mengirim lima field API dan melaporkan sukses sebagai status', async () => {
		const dialog = await openReset();
		await userEvent.type(within(dialog).getByLabelText('Username'), 'pilot');
		await userEvent.type(within(dialog).getByLabelText('New password'), 'newpass123');
		await userEvent.type(within(dialog).getByLabelText('Confirm new password'), 'newpass123');
		await userEvent.type(within(dialog).getByLabelText('Company name'), 'Skyward Air');

		await userEvent.click(within(dialog).getByRole('button', { name: 'Reset password' }));

		await vi.waitFor(() => expect(within(dialog).getByRole('status')).toBeInTheDocument());
		expect(mocks.auth.resetPassword).toHaveBeenCalledWith({
			username: 'pilot',
			newPassword: 'newpass123',
			companyName: 'Skyward Air',
			ceoName: '',
			hqAirportIata: ''
		});
	});

	it('melaporkan kegagalan sebagai alert, bukan sebagai sukses hijau', async () => {
		mocks.auth.resetPassword.mockResolvedValue(false);
		mocks.auth.error = 'invalid username';

		const dialog = await openReset();
		await userEvent.type(within(dialog).getByLabelText('Username'), 'pilot');
		await userEvent.type(within(dialog).getByLabelText('New password'), 'newpass123');
		await userEvent.type(within(dialog).getByLabelText('Confirm new password'), 'newpass123');

		await userEvent.click(within(dialog).getByRole('button', { name: 'Reset password' }));

		await vi.waitFor(() =>
			expect(within(dialog).getByRole('alert')).toHaveTextContent('invalid username')
		);
		expect(within(dialog).queryByRole('status')).toBeNull();
	});
});
