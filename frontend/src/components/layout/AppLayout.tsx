import { NavLink, Outlet, useNavigate } from 'react-router-dom'
import { toast } from 'sonner'
import { useAuth } from '../../auth/AuthContext'
import { env } from '../../config/env'
import { getErrorMessage } from '../../lib/errors'

/** Top-level application shell: header, nav, routed content, footer. */
export function AppLayout() {
  const { status, isAuthenticated, isAdmin, user, logout } = useAuth()
  const navigate = useNavigate()

  const handleLogout = async () => {
    try {
      await logout()
      toast.success('Signed out')
      navigate('/login', { replace: true })
    } catch (err) {
      toast.error(getErrorMessage(err, 'Unable to sign out'))
    }
  }

  return (
    <div className="app-shell">
      <header className="app-header">
        <span className="app-brand">{env.appName}</span>
        <nav className="app-nav">
          <NavLink to="/">Health</NavLink>
          {status !== 'loading' && !isAuthenticated && (
            <>
              <NavLink to="/login">Login</NavLink>
              <NavLink to="/register">Register</NavLink>
            </>
          )}
          {isAuthenticated && (
            <>
              {isAdmin && <NavLink to="/admin/users">Admin</NavLink>}
              <NavLink to="/projects">Projects</NavLink>
              <NavLink to="/profile">Profile</NavLink>
              <span className="app-greeting">Hi, {user?.name}</span>
              <button type="button" className="link-button" onClick={() => void handleLogout()}>
                Logout
              </button>
            </>
          )}
        </nav>
      </header>
      <main className="app-main">
        <Outlet />
      </main>
      <footer className="app-footer">Phase 2 — Authentication</footer>
    </div>
  )
}
