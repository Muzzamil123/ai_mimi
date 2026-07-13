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

/** Calls `GET /api/v1/health` on the Rails API. */
export async function fetchHealth(): Promise<HealthResponse> {
  const { data } = await apiClient.get<HealthResponse>('/health')
  return data
}
