import { services } from '$lib/core/di/services';
import { RoutesGateway } from './routes-gateway';

export function createRoutesGateway(): RoutesGateway {
	return new RoutesGateway(services.apiClient);
}
