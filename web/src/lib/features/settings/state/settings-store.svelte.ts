import type { Airport } from '$lib/features/routes/domain/airport';
import type { AirlineSettingsInput, SettingsGateway } from '../data/settings-gateway';

/** Store pengaturan. Port dari `SettingsCubit`. */
export class SettingsStore {
	state = $state<{
		loading: boolean;
		airports: Airport[];
		uiScale: number;
		error: string | null;
	}>({
		loading: false,
		airports: [],
		uiScale: 1,
		error: null
	});

	constructor(private readonly gateway: SettingsGateway) {}

	async load(): Promise<void> {
		this.state = { ...this.state, loading: true, error: null };
		try {
			const airports = await this.gateway.loadAirports();
			this.state = { ...this.state, loading: false, airports, error: null };
		} catch (err) {
			this.state = {
				...this.state,
				loading: false,
				error: err instanceof Error ? err.message : String(err)
			};
		}
	}

	async save(input: AirlineSettingsInput): Promise<boolean> {
		this.state = { ...this.state, error: null };
		try {
			await this.gateway.saveAirlineSettings(input);
			return true;
		} catch (err) {
			this.state = { ...this.state, error: err instanceof Error ? err.message : String(err) };
			return false;
		}
	}

	async reset(): Promise<boolean> {
		this.state = { ...this.state, error: null };
		try {
			await this.gateway.resetUserAirline();
			return true;
		} catch (err) {
			this.state = { ...this.state, error: err instanceof Error ? err.message : String(err) };
			return false;
		}
	}

	async deleteAccount(): Promise<boolean> {
		this.state = { ...this.state, error: null };
		try {
			await this.gateway.deleteAccount();
			return true;
		} catch (err) {
			this.state = { ...this.state, error: err instanceof Error ? err.message : String(err) };
			return false;
		}
	}

	setUiScale(value: number): void {
		this.state = { ...this.state, uiScale: value };
	}
}
