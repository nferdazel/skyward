import { services } from '$lib/core/di/services';
import { SimulationGateway } from './simulation-gateway';

export function createSimulationGateway(): SimulationGateway {
	return new SimulationGateway(services.apiClient);
}
