/* eslint-disable react-refresh/only-export-components */
import { createContext, useContext, useMemo, useState, type ReactNode } from 'react'
import { setAuthToken } from '../api/client'

export type UserRole = 'user' | 'admin'

export interface AuthUser {
  id: string
  email: string
  role: UserRole
}

interface AuthContextValue {
  user: AuthUser | null
  isAuthenticated: boolean
  login: (user: AuthUser, token: string) => void
  logout: () => void
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined)

/**
 * Placeholder authentication state for Phase 1. Real login/registration and
 * token persistence are implemented in Phase 2; the shape here is intentionally
 * forward-compatible so pages can already consume `useAuth()`.
 */
export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(null)

  const value = useMemo<AuthContextValue>(
    () => ({
      user,
      isAuthenticated: user !== null,
      login: (nextUser, token) => {
        setAuthToken(token)
        setUser(nextUser)
      },
      logout: () => {
        setAuthToken(null)
        setUser(null)
      },
    }),
    [user],
  )

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>
}

export function useAuth(): AuthContextValue {
  const ctx = useContext(AuthContext)
  if (!ctx) {
    throw new Error('useAuth must be used within an <AuthProvider>')
  }
  return ctx
}
