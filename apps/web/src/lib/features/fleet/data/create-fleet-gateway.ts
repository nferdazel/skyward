import { services } from '$lib/core/di/services';
import { FleetGateway } from './fleet-gateway';

export function createFleetGateway(): FleetGateway {
	return new FleetGateway(services.apiClient);
}
