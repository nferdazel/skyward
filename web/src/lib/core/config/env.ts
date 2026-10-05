/**
 * Konfigurasi runtime klien.
 *
 * Vite hanya menyuntik variabel ber-prefix `VITE_` ke bundle. Jika tidak diisi,
 * default ke API lokal (dev) — perilaku yang sama dengan klien Flutter lama
 * (`AppEnv.apiBaseUrl`).
 */
export const env = {
	apiBaseUrl:
		(import.meta.env.VITE_SKYWARD_API_URL as string | undefined) ?? 'http://localhost:8090'
} as const;
