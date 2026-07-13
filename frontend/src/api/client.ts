import axios, { AxiosError, type AxiosInstance } from 'axios'
import { env } from '../config/env'

/** Normalized error shape surfaced to the UI layer. */
export interface ApiError {
  status: number
  message: string
  details?: unknown
}

function normalizeError(error: AxiosError): ApiError {
  if (error.response) {
    const data = error.response.data as { message?: string; error?: string } | undefined
    return {
      status: error.response.status,
      message: data?.message ?? data?.error ?? error.message,
      details: error.response.data,
    }
  }
  return { status: 0, message: error.message || 'Network error — the API is unreachable.' }
}

/**
 * Shared HTTP client for the Rails API. Provider- and endpoint-specific logic
 * lives in dedicated `api/*.ts` modules, never in components.
 */
export const apiClient: AxiosInstance = axios.create({
  baseURL: env.apiBaseUrl,
  timeout: 15_000,
  headers: { 'Content-Type': 'application/json' },
})

// --- Authentication token injection (placeholder for Phase 2 auth) ---
let authToken: string | null = null

export function setAuthToken(token: string | null): void {
  authToken = token
}

apiClient.interceptors.request.use((config) => {
  if (authToken) {
    config.headers.Authorization = `Bearer ${authToken}`
  }
  return config
})

apiClient.interceptors.response.use(
  (response) => response,
  (error: AxiosError) => Promise.reject(normalizeError(error)),
)
