import { services } from '$lib/core/di/services';
import { AchievementsGateway } from './achievements-gateway';

export function createAchievementsGateway(): AchievementsGateway {
	return new AchievementsGateway(services.apiClient);
}
