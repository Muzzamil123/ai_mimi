/**
 * Centralized, typed access to build-time environment configuration.
 * Never read `import.meta.env` directly elsewhere — import from here so that
 * defaults and validation live in a single place.
 */
export const env = {
  apiBaseUrl: import.meta.env.VITE_API_BASE_URL ?? 'http://localhost:3000/api/v1',
  appName: import.meta.env.VITE_APP_NAME ?? 'AI Character Video Platform',
} as const

export type Env = typeof env
