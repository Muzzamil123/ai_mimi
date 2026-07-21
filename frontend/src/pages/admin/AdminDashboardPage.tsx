import { useCallback, useEffect, useState } from 'react'
import { getDashboard, type DashboardData } from '../../api/admin'
import { EmptyState } from '../../components/EmptyState'
import { Loading } from '../../components/Loading'
import { getErrorMessage } from '../../lib/errors'

type LoadState =
  | { kind: 'loading' }
  | { kind: 'ready'; data: DashboardData }
  | { kind: 'error'; message: string }

function StatusBreakdown({ title, counts }: { title: string; counts: Record<string, number> }) {
  const entries = Object.entries(counts)
  return (
    <div className="admin-card">
      <h3>{title}</h3>
      {entries.length === 0 ? (
        <p className="admin-muted">None yet</p>
      ) : (
        <ul className="admin-breakdown">
          {entries.map(([status, count]) => (
            <li key={status}>
              <span>{status}</span>
              <strong>{count}</strong>
            </li>
          ))}
        </ul>
      )}
    </div>
  )
}

export function AdminDashboardPage() {
  const [state, setState] = useState<LoadState>({ kind: 'loading' })

  const load = useCallback(async () => {
    setState({ kind: 'loading' })
    try {
      const data = await getDashboard()
      setState({ kind: 'ready', data })
    } catch (err) {
      setState({ kind: 'error', message: getErrorMessage(err, 'Failed to load the dashboard') })
    }
  }, [])

  useEffect(() => {
    void load()
  }, [load])

  if (state.kind === 'loading') return <Loading label="Loading dashboard…" />
  if (state.kind === 'error') {
    return (
      <EmptyState
        title="Unable to load the dashboard"
        description={state.message}
        action={
          <button type="button" onClick={() => void load()}>
            Retry
          </button>
        }
      />
    )
  }

  const { totals, health } = state.data

  return (
    <section className="admin-dashboard">
      <div className="page-header">
        <h1>Admin dashboard</h1>
        <button type="button" onClick={() => void load()}>
          Refresh
        </button>
      </div>

      <div className="stat-tiles">
        <div className="stat-tile">
          <span className="stat-tile__value">{totals.users}</span>
          <span className="stat-tile__label">Users</span>
        </div>
        <div className="stat-tile">
          <span className="stat-tile__value">{totals.projects}</span>
          <span className="stat-tile__label">Projects</span>
        </div>
        <div className="stat-tile">
          <span className="stat-tile__value">{totals.videos}</span>
          <span className="stat-tile__label">Videos</span>
        </div>
        <div className="stat-tile">
          <span className="stat-tile__value">{totals.generations}</span>
          <span className="stat-tile__label">Generations</span>
        </div>
        <div className="stat-tile" data-tone={totals.failed_generations > 0 ? 'error' : undefined}>
          <span className="stat-tile__value">{totals.failed_generations}</span>
          <span className="stat-tile__label">Failed generations</span>
        </div>
        <div className="stat-tile">
          <span className="stat-tile__value">{totals.audit_logs}</span>
          <span className="stat-tile__label">Audit entries</span>
        </div>
      </div>

      <div className="admin-card">
        <h3>System health</h3>
        <p>
          Status:{' '}
          <span className="status-badge" data-tone={health.status === 'ok' ? 'ok' : 'error'}>
            {health.status}
          </span>{' '}
          <span className="admin-muted">v{health.version}</span>
        </p>
        <ul className="admin-breakdown">
          {Object.entries(health.components).map(([component, value]) => (
            <li key={component}>
              <span>{component}</span>
              <span className="status-badge" data-tone={value === 'ok' ? 'ok' : 'error'}>
                {value}
              </span>
            </li>
          ))}
        </ul>
      </div>

      <div className="admin-grid">
        <StatusBreakdown title="Projects by status" counts={state.data.projects} />
        <StatusBreakdown title="Videos by status" counts={state.data.videos} />
        <StatusBreakdown title="Generations by status" counts={state.data.generations} />
        <StatusBreakdown title="Assets by validation" counts={state.data.assets} />
        <StatusBreakdown title="Emails by status" counts={state.data.email_deliveries} />
        <StatusBreakdown title="Users by status" counts={state.data.users} />
      </div>
    </section>
  )
}
