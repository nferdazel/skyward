import { services } from '$lib/core/di/services';
import { FinanceGateway } from './finance-gateway';

export function createFinanceGateway(): FinanceGateway {
	return new FinanceGateway(services.apiClient);
}
