import axios, {
  AxiosError,
  AxiosHeaders,
  type AxiosInstance,
  type InternalAxiosRequestConfig,
} from 'axios'
import { env } from '../config/env'

/** Normalized error shape surfaced to the UI layer. */
export interface ApiError {
  status: number
  message: string
  code?: string
  details?: unknown
}

/** Envelope returned by the Rails API for non-2xx responses. */
interface ErrorEnvelope {
  error?: { code?: string; messages?: string[] }
}

export function normalizeError(error: AxiosError): ApiError {
  if (error.response) {
    const data = error.response.data as ErrorEnvelope | undefined
    const envelope = data?.error
    const message =
      envelope?.messages && envelope.messages.length > 0
        ? envelope.messages.join(', ')
        : error.message
    return {
      status: error.response.status,
      message,
      code: envelope?.code,
      details: error.response.data,
    }
  }
  return { status: 0, message: error.message || 'Network error — the API is unreachable.' }
}

// --- Refresh-token persistence (localStorage) ---
const REFRESH_TOKEN_KEY = 'aicvp_refresh_token'

export function getStoredRefreshToken(): string | null {
  try {
    return localStorage.getItem(REFRESH_TOKEN_KEY)
  } catch {
    return null
  }
}

export function setStoredRefreshToken(token: string): void {
  try {
    localStorage.setItem(REFRESH_TOKEN_KEY, token)
  } catch {
    // Ignore storage failures (e.g. private mode); the app still works in-memory.
  }
}

export function clearStoredRefreshToken(): void {
  try {
    localStorage.removeItem(REFRESH_TOKEN_KEY)
  } catch {
    // Ignore storage failures.
  }
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

// --- Authentication token injection ---
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

// --- Transparent access-token refresh on 401 ---
const REFRESH_PATH = '/auth/refresh'
const SESSION_EXPIRED_EVENT = 'auth:session-expired'

/** Shape returned by POST /auth/refresh (subset used by the interceptor). */
interface RefreshTokensResponse {
  tokens: { access_token: string; refresh_token: string }
}

/** Requests we augment with a retry marker so a single retry is enforced. */
type RetriableConfig = InternalAxiosRequestConfig & { _retried?: boolean }

// A single in-flight refresh is shared across concurrent 401s.
let refreshPromise: Promise<string> | null = null

async function performRefresh(): Promise<string> {
  const refreshToken = getStoredRefreshToken()
  if (!refreshToken) {
    throw new Error('No refresh token available')
  }
  // Bare axios call to avoid recursive interceptors on the refresh request.
  const { data } = await axios.post<RefreshTokensResponse>(
    `${env.apiBaseUrl}${REFRESH_PATH}`,
    { refresh_token: refreshToken },
    { headers: { 'Content-Type': 'application/json' } },
  )
  setStoredRefreshToken(data.tokens.refresh_token)
  setAuthToken(data.tokens.access_token)
  return data.tokens.access_token
}

apiClient.interceptors.response.use(
  (response) => response,
  async (error: AxiosError) => {
    const original = error.config as RetriableConfig | undefined
    const status = error.response?.status
    const isRefreshCall = original?.url?.includes(REFRESH_PATH) ?? false

    if (
      status === 401 &&
      original &&
      !original._retried &&
      !isRefreshCall &&
      getStoredRefreshToken()
    ) {
      original._retried = true
      try {
        refreshPromise = refreshPromise ?? performRefresh()
        const accessToken = await refreshPromise
        refreshPromise = null
        const headers = AxiosHeaders.from(original.headers)
        headers.set('Authorization', `Bearer ${accessToken}`)
        original.headers = headers
        return apiClient(original)
      } catch {
        refreshPromise = null
        clearStoredRefreshToken()
        setAuthToken(null)
        if (typeof window !== 'undefined') {
          window.dispatchEvent(new Event(SESSION_EXPIRED_EVENT))
        }
      }
    }

    return Promise.reject(normalizeError(error))
  },
)
