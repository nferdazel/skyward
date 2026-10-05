import type { LeaderboardGateway } from '../data/leaderboard-gateway';
import type { CompetitorInsights, LeaderboardEntry } from '../domain/leaderboard-models';

/** Store papan peringkat. Port dari `LeaderboardCubit` (dimuat lazy). */
export class LeaderboardStore {
	state = $state<{
		loading: boolean;
		entries: LeaderboardEntry[];
		insights: CompetitorInsights | null;
		error: string | null;
	}>({
		loading: false,
		entries: [],
		insights: null,
		error: null
	});

	constructor(private readonly gateway: LeaderboardGateway) {}

	async load(): Promise<void> {
		this.state = { ...this.state, loading: true, error: null };
		try {
			const entries = await this.gateway.getGlobalLeaderboard();
			this.state = { ...this.state, loading: false, entries, error: null };
		} catch (err) {
			this.state = {
				...this.state,
				loading: false,
				error: err instanceof Error ? err.message : String(err)
			};
		}
	}

	async loadCompetitor(id: string, isBot: boolean): Promise<void> {
		try {
			const list = await this.gateway.getCompetitorInsights(id, isBot);
			this.state = { ...this.state, insights: list[0] ?? null };
		} catch (err) {
			this.state = { ...this.state, error: err instanceof Error ? err.message : String(err) };
		}
	}
}
