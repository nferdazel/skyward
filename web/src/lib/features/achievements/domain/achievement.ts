/** Achievement pemain. Port dari Flutter `Achievement`. */
export interface Achievement {
	id: string;
	achievementType: string;
	achievementName: string;
	description: string;
	unlockedAt: string;
}

/** Achievement yang baru dibuka (dari respons `/simulation/sync`), untuk toast. */
export interface NewAchievement {
	achievementType: string;
	achievementName: string;
	description: string;
}

function str(v: unknown, fallback = ''): string {
	return typeof v === 'string' ? v : fallback;
}

export function achievementFromMap(map: Record<string, unknown>): Achievement {
	return {
		id: str(map.id),
		achievementType: str(map.achievement_type),
		achievementName: str(map.achievement_name),
		description: str(map.description),
		unlockedAt: str(map.unlocked_at) || new Date(0).toISOString()
	};
}

export function newAchievementFromMap(map: Record<string, unknown>): NewAchievement {
	return {
		achievementType: str(map.achievement_type),
		achievementName: str(map.achievement_name),
		description: str(map.description)
	};
}
