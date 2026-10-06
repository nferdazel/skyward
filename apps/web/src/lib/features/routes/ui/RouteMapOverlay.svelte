<script lang="ts">
	import { onDestroy, onMount } from 'svelte';
	import 'leaflet/dist/leaflet.css';
	import type { Airport } from '../domain/airport';
	import type { UserRoute } from '../domain/route-models';

	/**
	 * Full-screen route map (Leaflet, dark CARTO tiles). Ported from the Flutter
	 * `_buildFullMap` layer: draws airports + route arcs. Presentation only — no
	 * economics here.
	 *
	 * Leaflet JS is dynamically imported so the static build has no Node/DOM
	 * dependency at build time; its CSS is imported statically so it is always
	 * bundled and present before the map initialises (a dynamically injected
	 * stylesheet can arrive after L.map() and leave the container unsized).
	 */
	type Props = {
		airports: Airport[];
		routes: UserRoute[];
		/** Optional planned leg (origin→destination) drawn as a preview line. */
		preview?: { origin: Airport; destination: Airport } | null;
		onmaptap?: (airport: Airport) => void;
	};

	let { airports, routes, preview = null, onmaptap }: Props = $props();
	let container: HTMLDivElement | undefined = $state();
	let cleanup: (() => void) | undefined;

	// eslint-disable-next-line @typescript-eslint/no-explicit-any
	type L = any;

	function greatCircle(a: Airport, b: Airport, steps: number): [number, number][] {
		const toRad = (d: number) => (d * Math.PI) / 180;
		const toDeg = (r: number) => (r * 180) / Math.PI;
		const lat1 = toRad(a.latitude);
		const lon1 = toRad(a.longitude);
		const lat2 = toRad(b.latitude);
		const lon2 = toRad(b.longitude);
		const d =
			2 *
			Math.asin(
				Math.sqrt(
					Math.sin((lat2 - lat1) / 2) ** 2 +
						Math.cos(lat1) * Math.cos(lat2) * Math.sin((lon2 - lon1) / 2) ** 2
				)
			);
		if (d === 0) return [];
		const out: [number, number][] = [];
		for (let i = 1; i < steps; i++) {
			const f = i / steps;
			const A = Math.sin((1 - f) * d) / Math.sin(d);
			const B = Math.sin(f * d) / Math.sin(d);
			const x = A * Math.cos(lat1) * Math.cos(lon1) + B * Math.cos(lat2) * Math.cos(lon2);
			const y = A * Math.cos(lat1) * Math.sin(lon1) + B * Math.cos(lat2) * Math.sin(lon2);
			const z = A * Math.sin(lat1) + B * Math.sin(lat2);
			out.push([toDeg(Math.atan2(z, Math.sqrt(x * x + y * y))), toDeg(Math.atan2(y, x))]);
		}
		return out;
	}

	onMount(() => {
		let cancelled = false;
		let map: L | undefined;
		let observer: ResizeObserver | undefined;
		void (async () => {
			if (!container) return;
			const Leaflet = (await import('leaflet')) as unknown as { default?: L } & L;
			const Lmod: L = Leaflet.default ?? Leaflet;
			if (cancelled || !container) return;

			map = Lmod.map(container, {
				worldCopyJump: true,
				zoomControl: true,
				attributionControl: true,
				minZoom: 0,
				maxZoom: 18
			}).setView([12, 108], 3);
			// Esri "Dark Gray Canvas" — no API key required, dark theme that
			// matches the command UI. (CARTO's free basemaps now return an
			// "API KEY REQUIRED" placeholder tile, so they were dropped.)
			Lmod.tileLayer(
				'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}',
				{
					attribution: 'Tiles © Esri — Esri, DeLorme, NAVTEQ',
					maxZoom: 16,
					minZoom: 0,
					crossOrigin: true
				}
			).addTo(map);

			const byIata = new Map(airports.map((a) => [a.iata, a]));
			const connected = new Set<string>();
			for (const r of routes) {
				connected.add(r.originIata);
				connected.add(r.destinationIata);
			}
			for (const iata of connected) {
				const a = byIata.get(iata);
				if (!a) continue;
				const marker = Lmod.circleMarker([a.latitude, a.longitude], {
					radius: 6,
					color: '#5B9EE0',
					fillColor: '#5B9EE0',
					fillOpacity: 0.9,
					weight: 1
				}).addTo(map);
				marker.bindTooltip(`${a.iata} — ${a.name}`);
				if (onmaptap) marker.on('click', () => onmaptap(a));
			}
			for (const r of routes) {
				const o = byIata.get(r.originIata);
				const d = byIata.get(r.destinationIata);
				if (!o || !d) continue;
				const arc = greatCircle(o, d, 18);
				Lmod.polyline([[o.latitude, o.longitude], ...arc, [d.latitude, d.longitude]], {
					color: '#3AAFA0',
					weight: 2.5,
					opacity: 0.72
				}).addTo(map);
			}
			if (preview) {
				const arc = greatCircle(preview.origin, preview.destination, 18);
				Lmod.polyline(
					[
						[preview.origin.latitude, preview.origin.longitude],
						...arc,
						[preview.destination.latitude, preview.destination.longitude]
					],
					{ color: '#5B9EE0', weight: 3, opacity: 0.9, dashArray: '6 6' }
				).addTo(map);
			}

			// Fix the classic "empty/partial map" case: Leaflet measures the
			// container at init; in an SPA it can be 0×0 or smaller than final
			// until layout settles. Re-measure on a few successive frames and on
			// every container resize.
			const mapRef = map;
			const revalidate = () => mapRef?.invalidateSize();
			requestAnimationFrame(() => {
				revalidate();
				requestAnimationFrame(revalidate);
			});
			setTimeout(revalidate, 250);
			if (container) {
				observer = new ResizeObserver(revalidate);
				observer.observe(container);
			}

			cleanup = () => {
				observer?.disconnect();
				mapRef?.remove();
			};
		})();
		return () => {
			cancelled = true;
		};
	});

	onDestroy(() => cleanup?.());
</script>

<div class="map-wrap">
	<div class="map" bind:this={container} aria-label="Route map" role="img"></div>
</div>

<style>
	.map-wrap {
		position: absolute;
		inset: 0;
	}
	.map {
		position: absolute;
		inset: 0;
		background: var(--color-bg);
	}
</style>
