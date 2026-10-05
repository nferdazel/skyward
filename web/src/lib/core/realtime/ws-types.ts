/** Event payload dari WebSocket skyward-api (Go hub). Port dari `GoRealtimeEvent`. */
export type RealtimeEventType = 'change' | 'pong';

export interface RealtimeEvent {
	type: RealtimeEventType;
	channel?: string;
	event?: string;
	at?: string;
}

export interface TimerApi {
	setTimeout(fn: () => void, ms: number): unknown;
	clearTimeout(handle: unknown): void;
	setInterval(fn: () => void, ms: number): unknown;
	clearInterval(handle: unknown): void;
}
