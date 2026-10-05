import { services } from '$lib/core/di/services';
import { AuthGateway } from '../data/auth-gateway';

/** Factory gateway auth — memakai klien & token store bersama. */
export function createAuthGateway(): AuthGateway {
	return new AuthGateway(services.apiClient, services.tokenStore);
}
