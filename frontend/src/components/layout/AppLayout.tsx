import { NavLink, Outlet } from 'react-router-dom'
import { env } from '../../config/env'

/** Top-level application shell: header, nav, routed content, footer. */
export function AppLayout() {
  return (
    <div className="app-shell">
      <header className="app-header">
        <span className="app-brand">{env.appName}</span>
        <nav className="app-nav">
          <NavLink to="/">Health</NavLink>
        </nav>
      </header>
      <main className="app-main">
        <Outlet />
      </main>
      <footer className="app-footer">Phase 1 — Foundation</footer>
    </div>
  )
}
