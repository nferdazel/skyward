import { services } from '$lib/core/di/services';
import { SettingsGateway } from './settings-gateway';

export function createSettingsGateway(): SettingsGateway {
	return new SettingsGateway(services.apiClient);
}
