import type { AcquireParams, FleetGateway, SeatConfig } from '../data/fleet-gateway';
import type { AircraftModel, UserFleetAircraft } from '../domain/fleet-models';

export interface FleetState {
	loading: boolean;
	aircraft: UserFleetAircraft[];
	catalog: AircraftModel[];
	error: string | null;
}

/**
 * Store armada. Port dari `FleetCubit`.
 *
 * Memuat armada + katalog, menjalankan mutasi (beli/sewa/perbaikan/jual/
 * sewa-berhenti/konfigurasi kursi), dan refetch saat event realtime
 * `fleet_aircraft`. Tidak menghitung nilai ekonomi apa pun.
 */
export class FleetStore {
	state = $state<FleetState>({
		loading: false,
		aircraft: [],
		catalog: [],
		error: null
	});

	constructor(private readonly gateway: FleetGateway) {}

	get aircraft(): UserFleetAircraft[] {
		return this.state.aircraft;
	}

	async load(): Promise<void> {
		this.state = { ...this.state, loading: true, error: null };
		try {
			const [aircraft, catalog] = await Promise.all([
				this.gateway.loadFleet(),
				this.gateway.loadCatalog()
			]);
			this.state = { loading: false, aircraft, catalog, error: null };
		} catch (err) {
			this.state = {
				...this.state,
				loading: false,
				error: err instanceof Error ? err.message : String(err)
			};
		}
	}

	/** Refetch armada saja (dipakai setelah mutasi / event realtime). */
	async refresh(): Promise<void> {
		try {
			const aircraft = await this.gateway.loadFleet();
			this.state = { ...this.state, aircraft };
		} catch (err) {
			this.state = { ...this.state, error: err instanceof Error ? err.message : String(err) };
		}
	}

	private async mutate(action: () => Promise<void>): Promise<boolean> {
		this.state = { ...this.state, error: null };
		try {
			await action();
			await this.refresh();
			return true;
		} catch (err) {
			this.state = { ...this.state, error: err instanceof Error ? err.message : String(err) };
			return false;
		}
	}

	purchase(params: AcquireParams): Promise<boolean> {
		return this.mutate(() => this.gateway.purchaseAircraft(params));
	}

	lease(params: AcquireParams): Promise<boolean> {
		return this.mutate(() => this.gateway.leaseAircraft(params));
	}

	repair(aircraftId: string): Promise<boolean> {
		return this.mutate(() => this.gateway.repairAircraft(aircraftId));
	}

	sell(aircraftId: string): Promise<boolean> {
		return this.mutate(() => this.gateway.sellAircraft(aircraftId));
	}

	terminateLease(aircraftId: string): Promise<boolean> {
		return this.mutate(() => this.gateway.terminateLease(aircraftId));
	}

	configureSeats(aircraftId: string, seats: SeatConfig): Promise<boolean> {
		return this.mutate(() => this.gateway.configureSeats(aircraftId, seats));
	}
}
