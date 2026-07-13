import { apiClient } from './client'

export type ComponentStatus = 'ok' | 'error' | 'unknown'

export interface HealthResponse {
  status: string
  version: string
  timestamp: string
  components: {
    database: ComponentStatus
    redis: ComponentStatus
    sidekiq: ComponentStatus
  }
}

/**
 * Calls `GET /api/v1/health`. A 503 means the API responded but a dependency is
 * degraded — we accept its body as data so the UI can show which component is
 * down. Only network failures / unexpected statuses reject.
 */
export async function fetchHealth(): Promise<HealthResponse> {
  const { data } = await apiClient.get<HealthResponse>('/health', {
    validateStatus: (status) => status === 200 || status === 503,
  })
  return data
}
