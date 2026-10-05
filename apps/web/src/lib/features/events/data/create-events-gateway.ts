import { services } from '$lib/core/di/services';
import { EventsGateway } from './events-gateway';

export function createEventsGateway(): EventsGateway {
	return new EventsGateway(services.apiClient);
}
