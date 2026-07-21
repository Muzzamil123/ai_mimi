import { useEffect, useState } from 'react'
import { NavLink, Link, Outlet, useNavigate } from 'react-router-dom'
import { toast } from 'sonner'
import { listNotifications } from '../../api/notifications'
import { useAuth } from '../../auth/AuthContext'
import { env } from '../../config/env'
import { getErrorMessage } from '../../lib/errors'

// How often to refresh the unread notification count in the nav.
const UNREAD_POLL_MS = 60_000
const MAINTENANCE_EVENT = 'app:maintenance'
const SUPPORT_EMAIL = 'support@aicvp.example'

/** Top-level application shell: header, nav, routed content, footer. */
export function AppLayout() {
  const { status, isAuthenticated, isAdmin, user, logout } = useAuth()
  const navigate = useNavigate()
  const [unread, setUnread] = useState(0)
  const [maintenance, setMaintenance] = useState(false)

  // Show a banner when the API reports it is in maintenance mode (503).
  useEffect(() => {
    const onMaintenance = () => setMaintenance(true)
    window.addEventListener(MAINTENANCE_EVENT, onMaintenance)
    return () => window.removeEventListener(MAINTENANCE_EVENT, onMaintenance)
  }, [])

  // Keep a lightweight unread count in the nav for authenticated users.
  useEffect(() => {
    if (!isAuthenticated) {
      setUnread(0)
      return
    }
    let active = true
    const refresh = () => {
      listNotifications({ page: 1 })
        .then((res) => {
          if (active) setUnread(res.meta.unread_count)
        })
        .catch(() => {
          /* non-critical; ignore */
        })
    }
    refresh()
    const timer = setInterval(refresh, UNREAD_POLL_MS)
    return () => {
      active = false
      clearInterval(timer)
    }
  }, [isAuthenticated])

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
      {maintenance && (
        <div className="maintenance-banner" role="alert">
          <span>
            The platform is temporarily down for maintenance. Some actions are unavailable.
          </span>
          <button
            type="button"
            className="link-button"
            aria-label="Dismiss maintenance notice"
            onClick={() => setMaintenance(false)}
          >
            Dismiss
          </button>
        </div>
      )}
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
              {isAdmin && <NavLink to="/admin">Admin</NavLink>}
              <NavLink to="/projects">Projects</NavLink>
              <NavLink to="/notifications">
                Notifications{unread > 0 && <span className="badge">{unread}</span>}
              </NavLink>
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
      <footer className="app-footer">
        <span>© {env.appName}</span>
        <nav className="app-footer-links">
          <Link to="/privacy">Privacy</Link>
          <Link to="/terms">Terms</Link>
          <a href={`mailto:${SUPPORT_EMAIL}`}>Support</a>
        </nav>
      </footer>
    </div>
  )
}
