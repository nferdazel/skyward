import type { AchievementsGateway } from '../data/achievements-gateway';
import type { Achievement } from '../domain/achievement';

/** Store achievement. Port dari `AchievementsCubit`. Reaktif ke simulation. */
export class AchievementsStore {
	state = $state<{ loading: boolean; achievements: Achievement[]; error: string | null }>({
		loading: false,
		achievements: [],
		error: null
	});

	constructor(private readonly gateway: AchievementsGateway) {}

	async load(): Promise<void> {
		this.state = { ...this.state, loading: true, error: null };
		try {
			const achievements = await this.gateway.loadAchievements();
			this.state = { loading: false, achievements, error: null };
		} catch (err) {
			this.state = {
				...this.state,
				loading: false,
				error: err instanceof Error ? err.message : String(err)
			};
		}
	}
}
