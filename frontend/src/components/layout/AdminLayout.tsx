import { NavLink, Outlet } from 'react-router-dom'

const ADMIN_LINKS: Array<{ to: string; label: string; end?: boolean }> = [
  { to: '/admin', label: 'Dashboard', end: true },
  { to: '/admin/users', label: 'Users' },
  { to: '/admin/projects', label: 'Projects' },
  { to: '/admin/videos', label: 'Videos' },
  { to: '/admin/generations', label: 'Generations' },
  { to: '/admin/emails', label: 'Emails' },
  { to: '/admin/costs', label: 'Costs' },
  { to: '/admin/budgets', label: 'Budgets' },
  { to: '/admin/pricing', label: 'Pricing' },
  { to: '/admin/audit-logs', label: 'Audit logs' },
  { to: '/admin/settings', label: 'Settings' },
  { to: '/admin/health', label: 'Health' },
]

/** Admin-portal shell: a sub-navigation bar plus the routed admin page. */
export function AdminLayout() {
  return (
    <section className="admin-portal">
      <nav className="admin-nav" aria-label="Admin sections">
        {ADMIN_LINKS.map((link) => (
          <NavLink key={link.to} to={link.to} end={link.end}>
            {link.label}
          </NavLink>
        ))}
      </nav>
      <div className="admin-content">
        <Outlet />
      </div>
    </section>
  )
}
