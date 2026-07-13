import { apiClient, clearStoredRefreshToken, setAuthToken, setStoredRefreshToken } from './client'

export type UserRole = 'user' | 'admin'
export type UserStatus = 'active' | 'suspended' | 'deleted'

export interface AuthUser {
  id: number
  name: string
  email: string
  role: UserRole
  status: UserStatus
  email_verified: boolean
  created_at: string
}

export interface AuthTokens {
  access_token: string
  refresh_token: string
  token_type: 'Bearer'
  expires_in: number
}

export interface AuthResponse {
  user: AuthUser
  tokens: AuthTokens
}

export interface RegisterPayload {
  name: string
  email: string
  password: string
}

export interface UpdateMePayload {
  name?: string
  password?: string
  current_password?: string
}

/** Persists tokens from an auth response and primes the request interceptor. */
function applySession(response: AuthResponse): AuthResponse {
  setAuthToken(response.tokens.access_token)
  setStoredRefreshToken(response.tokens.refresh_token)
  return response
}

export async function register(payload: RegisterPayload): Promise<AuthResponse> {
  const { data } = await apiClient.post<AuthResponse>('/auth/register', { user: payload })
  return applySession(data)
}

export async function login(email: string, password: string): Promise<AuthResponse> {
  const { data } = await apiClient.post<AuthResponse>('/auth/login', { email, password })
  return applySession(data)
}

export async function refresh(refreshToken: string): Promise<AuthResponse> {
  const { data } = await apiClient.post<AuthResponse>('/auth/refresh', {
    refresh_token: refreshToken,
  })
  return applySession(data)
}

export async function logout(refreshToken: string): Promise<void> {
  try {
    await apiClient.post('/auth/logout', { refresh_token: refreshToken })
  } finally {
    setAuthToken(null)
    clearStoredRefreshToken()
  }
}

export async function forgotPassword(email: string): Promise<void> {
  await apiClient.post('/auth/password/forgot', { email })
}

export async function resetPassword(token: string, password: string): Promise<void> {
  await apiClient.post('/auth/password/reset', { token, password })
}

export async function verifyEmail(token: string): Promise<void> {
  await apiClient.post('/auth/email/verify', { token })
}

export async function getMe(): Promise<AuthUser> {
  const { data } = await apiClient.get<AuthUser>('/me')
  return data
}

export async function updateMe(payload: UpdateMePayload): Promise<AuthUser> {
  const { data } = await apiClient.patch<AuthUser>('/me', { user: payload })
  return data
}

export async function deleteMe(): Promise<void> {
  await apiClient.delete('/me')
  setAuthToken(null)
  clearStoredRefreshToken()
}

export async function listUsers(): Promise<AuthUser[]> {
  const { data } = await apiClient.get<AuthUser[]>('/admin/users')
  return data
}
