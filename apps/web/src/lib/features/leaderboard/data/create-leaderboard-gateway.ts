import { services } from '$lib/core/di/services';
import { LeaderboardGateway } from './leaderboard-gateway';

export function createLeaderboardGateway(): LeaderboardGateway {
	return new LeaderboardGateway(services.apiClient);
}
