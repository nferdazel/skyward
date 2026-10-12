import { render, screen } from '@testing-library/svelte';
import userEvent from '@testing-library/user-event';
import { describe, expect, it, vi } from 'vitest';
import MultiSelectField from './MultiSelectField.svelte';

const options = ['Airbus', 'ATR', 'Boeing'];

describe('MultiSelectField', () => {
	it('shows ALL when nothing is selected', () => {
		render(MultiSelectField, {
			props: { label: 'Manufacturer', options, selected: [], onchange: vi.fn() }
		});
		expect(screen.getByText('ALL')).toBeInTheDocument();
	});

	it('shows the single selected value uppercased', () => {
		render(MultiSelectField, {
			props: { label: 'Manufacturer', options, selected: ['Airbus'], onchange: vi.fn() }
		});
		expect(screen.getByText('AIRBUS')).toBeInTheDocument();
	});

	it('counts a multi selection instead of listing it', () => {
		render(MultiSelectField, {
			props: { label: 'Range', options, selected: ['Airbus', 'Boeing'], onchange: vi.fn() }
		});
		expect(screen.getByText('2 SELECTED')).toBeInTheDocument();
	});

	it('commits the picked values only on Apply', async () => {
		const onchange = vi.fn();
		render(MultiSelectField, {
			props: { label: 'Manufacturer', options, selected: [], onchange }
		});

		await userEvent.click(screen.getByRole('button', { name: /manufacturer/i }));
		expect(screen.getByRole('dialog')).toBeInTheDocument();

		await userEvent.click(screen.getByRole('checkbox', { name: 'AIRBUS' }));
		expect(onchange).not.toHaveBeenCalled();

		await userEvent.click(screen.getByRole('button', { name: 'Apply' }));
		expect(onchange).toHaveBeenCalledWith(['Airbus']);
		expect(screen.queryByRole('dialog')).toBeNull();
	});

	it('drops changes on Cancel', async () => {
		const onchange = vi.fn();
		render(MultiSelectField, {
			props: { label: 'Manufacturer', options, selected: [], onchange }
		});

		await userEvent.click(screen.getByRole('button', { name: /manufacturer/i }));
		await userEvent.click(screen.getByRole('checkbox', { name: 'BOEING' }));
		await userEvent.click(screen.getByRole('button', { name: 'Cancel' }));

		expect(onchange).not.toHaveBeenCalled();
		expect(screen.queryByRole('dialog')).toBeNull();
	});

	it('starts the picker from the current selection and can untick it', async () => {
		const onchange = vi.fn();
		render(MultiSelectField, {
			props: { label: 'Manufacturer', options, selected: ['Airbus', 'Boeing'], onchange }
		});

		await userEvent.click(screen.getByRole('button', { name: /manufacturer/i }));
		expect(screen.getByRole('checkbox', { name: 'AIRBUS' })).toBeChecked();

		await userEvent.click(screen.getByRole('checkbox', { name: 'AIRBUS' }));
		await userEvent.click(screen.getByRole('button', { name: 'Apply' }));
		expect(onchange).toHaveBeenCalledWith(['Boeing']);
	});

	it('clears the selection', async () => {
		const onchange = vi.fn();
		render(MultiSelectField, {
			props: { label: 'Manufacturer', options, selected: ['Boeing'], onchange }
		});

		await userEvent.click(screen.getByRole('button', { name: /manufacturer/i }));
		await userEvent.click(screen.getByRole('button', { name: 'Clear' }));

		expect(onchange).toHaveBeenCalledWith([]);
		expect(screen.queryByRole('dialog')).toBeNull();
	});

	it('returns focus to the field when the picker closes', async () => {
		render(MultiSelectField, {
			props: { label: 'Manufacturer', options, selected: [], onchange: vi.fn() }
		});
		const field = screen.getByRole('button', { name: /manufacturer/i });

		await userEvent.click(field);
		await userEvent.click(screen.getByRole('button', { name: 'Apply' }));

		expect(document.activeElement).toBe(field);
	});
});
