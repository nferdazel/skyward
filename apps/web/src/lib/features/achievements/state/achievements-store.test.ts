import { describe, expect, it, vi } from 'vitest';
import { AchievementsStore } from './achievements-store.svelte';
import type { AchievementsGateway } from '../data/achievements-gateway';
import type { Achievement } from '../domain/achievement';

const sample: Achievement = {
	id: 'a1',
	achievementType: 'first_route',
	achievementName: 'First Route',
	description: 'Open your first route',
	unlockedAt: '2026-01-01T00:00:00.000Z'
};

function stubGateway(over: Partial<AchievementsGateway> = {}): AchievementsGateway {
	return {
		loadAchievements: vi.fn().mockResolvedValue([]),
		...over
	} as unknown as AchievementsGateway;
}

describe('AchievementsStore', () => {
	it('load fills achievements', async () => {
		const store = new AchievementsStore(
			stubGateway({ loadAchievements: vi.fn().mockResolvedValue([sample]) })
		);

		await store.load();

		expect(store.state.achievements).toEqual([sample]);
		expect(store.state.loading).toBe(false);
		expect(store.state.error).toBeNull();
	});

	it('load records the error when the gateway rejects', async () => {
		const store = new AchievementsStore(
			stubGateway({ loadAchievements: vi.fn().mockRejectedValue(new Error('boom')) })
		);

		await store.load();

		expect(store.state.error).toBe('boom');
		expect(store.state.loading).toBe(false);
	});
});
