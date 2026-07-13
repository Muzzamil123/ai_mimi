import { Link, Navigate, Outlet, useLocation } from 'react-router-dom'
import { useAuth } from '../auth/AuthContext'
import { EmptyState } from '../components/EmptyState'
import { Loading } from '../components/Loading'

/** Gates a subtree behind admin privileges. */
export function AdminRoute() {
  const { status, isAuthenticated, isAdmin } = useAuth()
  const location = useLocation()

  if (status === 'loading') {
    return <Loading label="Checking your session…" />
  }

  if (!isAuthenticated) {
    return <Navigate to="/login" replace state={{ from: location }} />
  }

  if (!isAdmin) {
    return (
      <EmptyState
        title="403 — Forbidden"
        description="You do not have permission to view this page."
        action={<Link to="/">Go home</Link>}
      />
    )
  }

  return <Outlet />
}
