import { services } from '$lib/core/di/services';
import { BankGateway } from './bank-gateway';

export function createBankGateway(): BankGateway {
	return new BankGateway(services.apiClient);
}
