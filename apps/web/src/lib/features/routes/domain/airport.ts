/** Bandara. Port dari Flutter `Airport`. */
export interface Airport {
	iata: string;
	name: string;
	city: string;
	country: string;
	latitude: number;
	longitude: number;
	demandIndex: number;
}

function str(v: unknown, fallback = ''): string {
	return typeof v === 'string' ? v : fallback;
}
function num(v: unknown, fallback = 0): number {
	return typeof v === 'number' && Number.isFinite(v) ? v : fallback;
}

export function airportFromMap(map: Record<string, unknown>): Airport {
	return {
		iata: str(map.iata),
		name: str(map.name, str(map.iata)),
		city: str(map.city),
		country: str(map.country),
		latitude: num(map.latitude),
		longitude: num(map.longitude),
		demandIndex: num(map.demand_index, 50)
	};
}

const EARTH_RADIUS_KM = 6371.0;
const toRadians = (deg: number) => (deg * Math.PI) / 180;

/** Jarak lingkaran besar (Haversine) antara dua bandara, dalam km. */
export function calculateDistance(a: Airport, b: Airport): number {
	const dLat = toRadians(b.latitude - a.latitude);
	const dLon = toRadians(b.longitude - a.longitude);
	const lat1 = toRadians(a.latitude);
	const lat2 = toRadians(b.latitude);
	const h = Math.sin(dLat / 2) ** 2 + Math.sin(dLon / 2) ** 2 * Math.cos(lat1) * Math.cos(lat2);
	return EARTH_RADIUS_KM * 2 * Math.asin(Math.sqrt(h));
}

/** GAME-08: bandara terdekat dalam radius, untuk saran rute pertama. */
export function nearestWithin(
	home: Airport,
	airports: Iterable<Airport>,
	maxDistanceKm = 1500
): Airport | null {
	let best: Airport | null = null;
	let bestDistance = Infinity;
	for (const airport of airports) {
		if (airport.iata === home.iata) continue;
		const distance = calculateDistance(home, airport);
		if (distance <= 0 || distance > maxDistanceKm) continue;
		if (distance < bestDistance) {
			best = airport;
			bestDistance = distance;
		}
	}
	return best;
}
