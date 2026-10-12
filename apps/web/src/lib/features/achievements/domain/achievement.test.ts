import { describe, expect, it } from 'vitest';
import { achievementFromMap, newAchievementFromMap } from './achievement';

describe('achievementFromMap', () => {
	it('maps a full row', () => {
		expect(
			achievementFromMap({
				id: 'a1',
				achievement_type: 'first_route',
				achievement_name: 'First Route',
				description: 'Open your first route',
				unlocked_at: '2026-01-01T00:00:00.000Z'
			})
		).toEqual({
			id: 'a1',
			achievementType: 'first_route',
			achievementName: 'First Route',
			description: 'Open your first route',
			unlockedAt: '2026-01-01T00:00:00.000Z'
		});
	});

	it('falls back for missing/invalid fields', () => {
		const a = achievementFromMap({ id: 42, unlocked_at: '' });
		expect(a.id).toBe('');
		expect(a.achievementType).toBe('');
		expect(a.unlockedAt).toBe(new Date(0).toISOString());
	});
});

describe('newAchievementFromMap', () => {
	it('maps the sync payload shape', () => {
		expect(
			newAchievementFromMap({
				achievement_type: 'first_route',
				achievement_name: 'First Route',
				description: 'Open your first route'
			})
		).toEqual({
			achievementType: 'first_route',
			achievementName: 'First Route',
			description: 'Open your first route'
		});
	});
});
