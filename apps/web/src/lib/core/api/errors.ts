/**
 * Error klien untuk panggilan ke skyward-api.
 *
 * `code` mengikuti error envelope Go (`internal/httperr`): `unauthorized`,
 * `validation`, `not_found`, `rate_limited`, `internal`, plus nilai transport
 * `network` dan `timeout`. Port dari Flutter `ApiException`.
 */
export type ApiErrorCode =
	'unauthorized' | 'validation' | 'not_found' | 'rate_limited' | 'internal' | 'network' | 'timeout';

export class ApiError extends Error {
	readonly code: ApiErrorCode;
	readonly statusCode?: number;

	constructor(message: string, code: ApiErrorCode = 'internal', statusCode?: number) {
		super(message);
		this.name = 'ApiError';
		this.code = code;
		this.statusCode = statusCode;
	}

	get isUnauthorized(): boolean {
		return this.code === 'unauthorized' || this.statusCode === 401;
	}
}
