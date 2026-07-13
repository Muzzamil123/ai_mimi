/* eslint-disable react-refresh/only-export-components */
import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useRef,
  useState,
  type ReactNode,
} from 'react'
import { toast } from 'sonner'
import {
  deleteMe,
  getMe,
  login as loginRequest,
  logout as logoutRequest,
  refresh as refreshRequest,
  register as registerRequest,
  updateMe,
  type AuthUser,
  type UpdateMePayload,
} from '../api/auth'
import { getStoredRefreshToken } from '../api/client'

export type AuthStatus = 'loading' | 'authenticated' | 'anonymous'

interface AuthContextValue {
  user: AuthUser | null
  status: AuthStatus
  isAuthenticated: boolean
  isAdmin: boolean
  login: (email: string, password: string) => Promise<void>
  register: (name: string, email: string, password: string) => Promise<void>
  logout: () => Promise<void>
  updateProfile: (payload: UpdateMePayload) => Promise<void>
  deleteAccount: () => Promise<void>
  reloadProfile: () => Promise<void>
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined)

const SESSION_EXPIRED_EVENT = 'auth:session-expired'

/**
 * Real authentication state. On mount it attempts to restore a session from the
 * persisted refresh token; token persistence itself lives in the api layer.
 */
export function AuthProvider({ children }: { children: ReactNode }) {
  const [user, setUser] = useState<AuthUser | null>(null)
  const [status, setStatus] = useState<AuthStatus>('loading')
  // Guards StrictMode's double mount from firing two restore attempts.
  const restored = useRef(false)

  useEffect(() => {
    if (restored.current) return
    restored.current = true

    const refreshToken = getStoredRefreshToken()
    if (!refreshToken) {
      setStatus('anonymous')
      return
    }

    let active = true
    void (async () => {
      try {
        const { user: restoredUser } = await refreshRequest(refreshToken)
        if (!active) return
        setUser(restoredUser)
        setStatus('authenticated')
      } catch {
        if (!active) return
        setUser(null)
        setStatus('anonymous')
      }
    })()

    return () => {
      active = false
    }
  }, [])

  useEffect(() => {
    const handleExpired = () => {
      setUser(null)
      setStatus('anonymous')
      toast.error('Your session expired. Please sign in again.')
    }
    window.addEventListener(SESSION_EXPIRED_EVENT, handleExpired)
    return () => window.removeEventListener(SESSION_EXPIRED_EVENT, handleExpired)
  }, [])

  const login = useCallback(async (email: string, password: string) => {
    const { user: authUser } = await loginRequest(email, password)
    setUser(authUser)
    setStatus('authenticated')
  }, [])

  const register = useCallback(async (name: string, email: string, password: string) => {
    const { user: authUser } = await registerRequest({ name, email, password })
    setUser(authUser)
    setStatus('authenticated')
  }, [])

  const logout = useCallback(async () => {
    const refreshToken = getStoredRefreshToken()
    try {
      if (refreshToken) {
        await logoutRequest(refreshToken)
      }
    } finally {
      setUser(null)
      setStatus('anonymous')
    }
  }, [])

  const updateProfile = useCallback(async (payload: UpdateMePayload) => {
    const updated = await updateMe(payload)
    setUser(updated)
  }, [])

  const deleteAccount = useCallback(async () => {
    await deleteMe()
    setUser(null)
    setStatus('anonymous')
  }, [])

  const reloadProfile = useCallback(async () => {
    const fresh = await getMe()
    setUser(fresh)
    setStatus('authenticated')
  }, [])

  const value = useMemo<AuthContextValue>(
    () => ({
      user,
      status,
      isAuthenticated: status === 'authenticated' && user !== null,
      isAdmin: user?.role === 'admin',
      login,
      register,
      logout,
      updateProfile,
      deleteAccount,
      reloadProfile,
    }),
    [user, status, login, register, logout, updateProfile, deleteAccount, reloadProfile],
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
