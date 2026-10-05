<script lang="ts">
	import { onDestroy, onMount } from 'svelte';
	import type { Airport } from '../domain/airport';
	import type { UserRoute } from '../domain/route-models';

	/**
	 * Peta rute memakai Leaflet (BSD, tile OpenStreetMap). Dimuat hanya di
	 * browser (dynamic import) supaya build statis tetap jalan tanpa Node/DOM
	 * saat build.
	 *
	 * Peta murni presentasi: menggambar bandara + garis rute dari data server.
	 * Tidak ada perhitungan ekonomi di sini.
	 */
	type Props = {
		airports: Airport[];
		routes: UserRoute[];
	};

	let { airports, routes }: Props = $props();
	let container: HTMLDivElement | undefined = $state();
	let cleanup: (() => void) | undefined;

	onMount(() => {
		let cancelled = false;
		void (async () => {
			if (!container) return;
			const L = await import('leaflet');
			await import('leaflet/dist/leaflet.css');
			if (cancelled || !container) return;

			const map = L.map(container, { worldCopyJump: true }).setView([20, 20], 2);
			L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
				attribution: '© OpenStreetMap',
				maxZoom: 8
			}).addTo(map);

			const byIata = new Map(airports.map((a) => [a.iata, a]));
			for (const a of airports) {
				L.circleMarker([a.latitude, a.longitude], {
					radius: 3,
					color: '#5B9EE0',
					fillOpacity: 0.8
				})
					.bindTooltip(`${a.iata} — ${a.name}`)
					.addTo(map);
			}
			for (const r of routes) {
				const origin = byIata.get(r.originIata);
				const dest = byIata.get(r.destinationIata);
				if (!origin || !dest) continue;
				L.polyline(
					[
						[origin.latitude, origin.longitude],
						[dest.latitude, dest.longitude]
					],
					{ color: '#3AAFA0', weight: 1.5, opacity: 0.8 }
				).addTo(map);
			}

			cleanup = () => map.remove();
		})();
		return () => {
			cancelled = true;
		};
	});

	onDestroy(() => cleanup?.());
</script>

<div class="map" bind:this={container} aria-label="Peta rute" role="img"></div>

<style>
	.map {
		width: 100%;
		height: 360px;
		border: 0.5px solid var(--color-border);
		border-radius: var(--radius-default);
		background: var(--color-surface);
	}
</style>
