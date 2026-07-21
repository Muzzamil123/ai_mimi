import { useCallback, useEffect, useState } from 'react'
import { getHealth, type HealthReport } from '../../api/admin'
import { EmptyState } from '../../components/EmptyState'
import { Loading } from '../../components/Loading'
import { getErrorMessage } from '../../lib/errors'

type LoadState =
  | { kind: 'loading' }
  | { kind: 'ready'; report: HealthReport }
  | { kind: 'error'; message: string }

export function AdminHealthPage() {
  const [state, setState] = useState<LoadState>({ kind: 'loading' })

  const load = useCallback(async () => {
    setState({ kind: 'loading' })
    try {
      const report = await getHealth()
      setState({ kind: 'ready', report })
    } catch (err) {
      setState({ kind: 'error', message: getErrorMessage(err, 'Failed to load health') })
    }
  }, [])

  useEffect(() => {
    void load()
  }, [load])

  if (state.kind === 'loading') return <Loading label="Checking system health…" />
  if (state.kind === 'error') {
    return (
      <EmptyState
        title="Unable to load health"
        description={state.message}
        action={
          <button type="button" onClick={() => void load()}>
            Retry
          </button>
        }
      />
    )
  }

  const { report } = state

  return (
    <section className="admin-health">
      <div className="page-header">
        <h1>System health</h1>
        <button type="button" onClick={() => void load()}>
          Refresh
        </button>
      </div>

      <div className="admin-card">
        <p>
          Overall:{' '}
          <span className="status-badge" data-tone={report.status === 'ok' ? 'ok' : 'error'}>
            {report.status}
          </span>{' '}
          <span className="admin-muted">version {report.version}</span>
        </p>
        <div className="health-grid">
          {Object.entries(report.components).map(([component, value]) => (
            <div key={component} className="admin-card">
              <h3>{component}</h3>
              <span className="status-badge" data-tone={value === 'ok' ? 'ok' : 'error'}>
                {value}
              </span>
            </div>
          ))}
        </div>
      </div>
    </section>
  )
}
