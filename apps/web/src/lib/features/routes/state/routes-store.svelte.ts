import type { RoutesGateway } from '../data/routes-gateway';
import type { Airport } from '../domain/airport';
import type { RoutePlanAssessment } from '../domain/route-assessment';
import type { UserRoute } from '../domain/route-models';
import type { UserFleetAircraft } from '$lib/features/fleet/domain/fleet-models';

export interface RoutesState {
	loading: boolean;
	routes: UserRoute[];
	airports: Airport[];
	availableFleet: UserFleetAircraft[];
	assessments: Record<string, RoutePlanAssessment>;
	groundingThreshold: number;
	error: string | null;
}

/**
 * Store rute. Port dari `RoutesCubit`.
 *
 * Memuat rute + bandara + armada tersedia + penilaian batch; mutasi
 * (buat/assign/update/hapus); refetch saat event realtime `route_assignments`.
 * Ekonomi rute berasal dari server (`/routes/assess*`), bukan dihitung di sini.
 */
export class RoutesStore {
	state = $state<RoutesState>({
		loading: false,
		routes: [],
		airports: [],
		availableFleet: [],
		assessments: {},
		groundingThreshold: 40,
		error: null
	});

	constructor(private readonly gateway: RoutesGateway) {}

	get routes(): UserRoute[] {
		return this.state.routes;
	}

	async load(): Promise<void> {
		this.state = { ...this.state, loading: true, error: null };
		try {
			const [routes, airports, availableFleet, assessments, groundingThreshold] = await Promise.all(
				[
					this.gateway.loadRoutes(),
					this.gateway.loadAirports(),
					this.gateway.loadAvailableFleet(),
					this.gateway.loadRouteAssessments(),
					this.gateway.loadGroundingThreshold()
				]
			);
			this.state = {
				loading: false,
				routes,
				airports,
				availableFleet,
				assessments,
				groundingThreshold,
				error: null
			};
		} catch (err) {
			this.state = {
				...this.state,
				loading: false,
				error: err instanceof Error ? err.message : String(err)
			};
		}
	}

	/** Refetch rute + penilaian (dipakai setelah mutasi / event realtime). */
	async refresh(): Promise<void> {
		try {
			const [routes, assessments] = await Promise.all([
				this.gateway.loadRoutes(),
				this.gateway.loadRouteAssessments()
			]);
			this.state = { ...this.state, routes, assessments };
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

	create(input: {
		originIata: string;
		destinationIata: string;
		distanceKm: number;
		ticketPrice: number;
		flightsPerWeek: number;
	}): Promise<boolean> {
		return this.mutate(() => this.gateway.createRoute(input));
	}

	assign(routeId: string, aircraftId: string | null): Promise<boolean> {
		return this.mutate(() => this.gateway.assignAircraft(routeId, aircraftId));
	}

	update(routeId: string, ticketPrice: number, flightsPerWeek: number): Promise<boolean> {
		return this.mutate(() => this.gateway.updateRoute(routeId, ticketPrice, flightsPerWeek));
	}

	remove(routeId: string): Promise<boolean> {
		return this.mutate(() => this.gateway.deleteRoute(routeId));
	}

	/** Penilaian server untuk satu rute usulan (belum disimpan). */
	assess(input: {
		originIata: string;
		destinationIata: string;
		ticketPrice: number;
		flightsPerWeek: number;
		aircraftId?: string;
	}): Promise<RoutePlanAssessment | null> {
		return this.gateway.assessRoute(input);
	}
}
