/**
 * Event domain internal. Port dari Flutter `core/sync/domain_events.dart`.
 * Dipakai untuk koordinasi reload antar-store tanpa referensi silang langsung.
 */
export interface DomainEvent {
	readonly kind: string;
	readonly timestamp: number;
}

export interface FleetUpdatedEvent extends DomainEvent {
	kind: 'fleet_updated';
	userId?: string;
	action?: string;
	aircraftId?: string;
}

export interface RouteUpdatedEvent extends DomainEvent {
	kind: 'route_updated';
	userId?: string;
	action?: string;
	routeId?: string;
}

export interface BankTransactionEvent extends DomainEvent {
	kind: 'bank_transaction';
	userId?: string;
	amount?: number;
	transactionType?: string;
}

export interface SeasonClockTickEvent extends DomainEvent {
	kind: 'season_clock_tick';
	currentTick?: number;
	seasonName?: string;
}

export type AppDomainEvent =
	FleetUpdatedEvent | RouteUpdatedEvent | BankTransactionEvent | SeasonClockTickEvent;

function withTimestamp<T extends Omit<DomainEvent, 'timestamp'>>(
	event: T
): T & { timestamp: number } {
	return { ...event, timestamp: Date.now() };
}

export function fleetUpdated(
	payload: Omit<FleetUpdatedEvent, 'kind' | 'timestamp'>
): FleetUpdatedEvent {
	return withTimestamp({ kind: 'fleet_updated', ...payload }) as FleetUpdatedEvent;
}

export function routeUpdated(
	payload: Omit<RouteUpdatedEvent, 'kind' | 'timestamp'>
): RouteUpdatedEvent {
	return withTimestamp({ kind: 'route_updated', ...payload }) as RouteUpdatedEvent;
}

export function bankTransaction(
	payload: Omit<BankTransactionEvent, 'kind' | 'timestamp'>
): BankTransactionEvent {
	return withTimestamp({ kind: 'bank_transaction', ...payload }) as BankTransactionEvent;
}

export function seasonClockTick(
	payload: Omit<SeasonClockTickEvent, 'kind' | 'timestamp'>
): SeasonClockTickEvent {
	return withTimestamp({ kind: 'season_clock_tick', ...payload }) as SeasonClockTickEvent;
}
