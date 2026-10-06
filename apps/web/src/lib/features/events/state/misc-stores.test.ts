import { describe, expect, it, vi } from 'vitest';
import { EventsStore } from '$lib/features/events/state/events-store.svelte';
import { AchievementsStore } from '$lib/features/achievements/state/achievements-store.svelte';
import { LeaderboardStore } from '$lib/features/leaderboard/state/leaderboard-store.svelte';
import { SettingsStore } from '$lib/features/settings/state/settings-store.svelte';
import { SettingsGateway } from '$lib/features/settings/data/settings-gateway';
import { gameEventFromMap, isExpired, remainingMs } from '$lib/features/events/domain/game-event';
import type { EventsGateway as EventsGatewayType } from '$lib/features/events/data/events-gateway';
import type { AchievementsGateway } from '$lib/features/achievements/data/achievements-gateway';
import type { LeaderboardGateway } from '$lib/features/leaderboard/data/leaderboard-gateway';
import { competitorInsightsFromMap } from '$lib/features/leaderboard/domain/leaderboard-models';
import type { ApiClient } from '$lib/core/api/api-client';

describe('events domain', () => {
	it('reports expiry and remaining duration', () => {
		const event = gameEventFromMap({
			id: 'e1',
			start_game_time: '2030-01-01T00:00:00Z',
			end_game_time: '2030-01-02T00:00:00Z'
		});
		const mid = Date.parse('2030-01-01T12:00:00Z');
		expect(remainingMs(event, mid)).toBe(12 * 3600 * 1000);
		expect(isExpired(event, mid)).toBe(false);
		expect(isExpired(event, Date.parse('2030-01-03T00:00:00Z'))).toBe(true);
	});
});

describe('EventsStore', () => {
	it('filters expired events in activeEvents', async () => {
		const gateway = {
			loadActiveEvents: vi
				.fn()
				.mockResolvedValue([
					gameEventFromMap({ id: 'a', end_game_time: '2030-01-01T00:00:00Z' }),
					gameEventFromMap({ id: 'b', end_game_time: '2030-01-05T00:00:00Z' })
				])
		} as unknown as EventsGatewayType;
		const store = new EventsStore(gateway);
		await store.load();

		const now = Date.parse('2030-01-02T00:00:00Z');
		expect(store.activeEvents(now).map((e) => e.id)).toEqual(['b']);
	});
});

describe('AchievementsStore', () => {
	it('loads achievements', async () => {
		const gateway = {
			loadAchievements: vi.fn().mockResolvedValue([{ id: 'a1' }])
		} as unknown as AchievementsGateway;
		const store = new AchievementsStore(gateway);
		await store.load();
		expect(store.state.achievements).toHaveLength(1);
	});
});

describe('LeaderboardStore', () => {
	it('loads entries and competitor insights', async () => {
		const gateway = {
			getGlobalLeaderboard: vi.fn().mockResolvedValue([{ id: 'u1' }]),
			getCompetitorInsights: vi
				.fn()
				.mockResolvedValue([competitorInsightsFromMap({ company_name: 'Rival' })])
		} as unknown as LeaderboardGateway;
		const store = new LeaderboardStore(gateway);

		await store.load();
		await store.loadCompetitor('u1', true);

		expect(store.state.entries).toHaveLength(1);
		expect(store.state.insights?.companyName).toBe('Rival');
	});
});

describe('SettingsGateway', () => {
	it('PATCH /settings sends unprefixed keys and omits undefined optionals', async () => {
		const patch = vi.fn().mockResolvedValue(undefined);
		const gateway = new SettingsGateway({ patch } as unknown as ApiClient);

		await gateway.saveAirlineSettings({ companyName: 'Sky', autoGroundingThreshold: 45 });

		expect(patch).toHaveBeenCalledWith('/settings', {
			company_name: 'Sky',
			auto_grounding_threshold: 45
		});
	});
});

describe('SettingsStore', () => {
	it('save returns false and records the error on failure', async () => {
		const gateway = {
			loadAirports: vi.fn().mockResolvedValue([]),
			saveAirlineSettings: vi.fn().mockRejectedValue(new Error('Company name cannot be empty.'))
		} as unknown as SettingsGateway;
		const store = new SettingsStore(gateway);

		const ok = await store.save({ companyName: '' });

		expect(ok).toBe(false);
		expect(store.state.error).toBe('Company name cannot be empty.');
	});
});
