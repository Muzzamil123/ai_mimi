import { useCallback, useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { toast } from 'sonner'
import {
  exportCosts,
  getCosts,
  getProjectSpend,
  getUserSpend,
  type CostGroupRow,
  type CostReport,
  type SpendRow,
} from '../../api/adminCosts'
import { EmptyState } from '../../components/EmptyState'
import { Loading } from '../../components/Loading'
import { getErrorMessage } from '../../lib/errors'

type LoadState =
  | { kind: 'loading' }
  | { kind: 'ready'; report: CostReport; users: SpendRow[]; projects: SpendRow[] }
  | { kind: 'error'; message: string }

function money(value: number): string {
  return `$${value.toFixed(4)}`
}

// A share-of-max horizontal bar (no chart library). Accessible via aria + text.
function BarRows({ rows }: { rows: CostGroupRow[] }) {
  if (rows.length === 0) return <p className="admin-muted">No usage in this range.</p>
  const max = Math.max(...rows.map((r) => r.estimated_cost), 0.0000001)
  return (
    <ul className="cost-bars">
      {rows.map((row) => (
        <li key={row.key ?? 'unknown'} className="cost-bar-row">
          <span className="cost-bar-label">{row.key ?? 'unknown'}</span>
          <span className="cost-bar-track" aria-hidden="true">
            <span className="cost-bar-fill" style={{ width: `${(row.estimated_cost / max) * 100}%` }} />
          </span>
          <span className="cost-bar-value">
            {money(row.estimated_cost)} <span className="admin-muted">({row.count})</span>
          </span>
        </li>
      ))}
    </ul>
  )
}

function SpendTable({ title, rows }: { title: string; rows: SpendRow[] }) {
  return (
    <div className="admin-card">
      <h3>{title}</h3>
      {rows.length === 0 ? (
        <p className="admin-muted">No spend recorded.</p>
      ) : (
        <div className="table-scroll">
          <table className="data-table">
            <thead>
              <tr>
                <th>Name</th>
                <th>Calls</th>
                <th>Est. cost</th>
              </tr>
            </thead>
            <tbody>
              {rows.map((row) => (
                <tr key={row.id}>
                  <td>{row.label ?? `#${row.id}`}</td>
                  <td>{row.count}</td>
                  <td>{money(row.estimated_cost)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}

export function AdminCostsPage() {
  const [from, setFrom] = useState('')
  const [to, setTo] = useState('')
  const [state, setState] = useState<LoadState>({ kind: 'loading' })
  const [exporting, setExporting] = useState(false)

  const load = useCallback(async () => {
    setState({ kind: 'loading' })
    const params = { from: from || undefined, to: to || undefined }
    try {
      const [report, users, projects] = await Promise.all([
        getCosts(params),
        getUserSpend(params),
        getProjectSpend(params),
      ])
      setState({ kind: 'ready', report, users: users.rows, projects: projects.rows })
    } catch (err) {
      setState({ kind: 'error', message: getErrorMessage(err, 'Failed to load costs') })
    }
  }, [from, to])

  useEffect(() => {
    void load()
  }, [load])

  const onExport = async () => {
    setExporting(true)
    try {
      await exportCosts({ from: from || undefined, to: to || undefined })
    } catch (err) {
      toast.error(getErrorMessage(err, 'Unable to export usage'))
    } finally {
      setExporting(false)
    }
  }

  return (
    <section className="admin-costs">
      <div className="page-header">
        <h1>Costs</h1>
      </div>

      <form
        className="admin-filters"
        onSubmit={(event) => {
          event.preventDefault()
          void load()
        }}
      >
        <div className="field">
          <label htmlFor="cost-from">From</label>
          <input id="cost-from" type="date" value={from} onChange={(e) => setFrom(e.target.value)} />
        </div>
        <div className="field">
          <label htmlFor="cost-to">To</label>
          <input id="cost-to" type="date" value={to} onChange={(e) => setTo(e.target.value)} />
        </div>
        <button type="submit">Apply</button>
        <button type="button" disabled={exporting} onClick={() => void onExport()}>
          {exporting ? 'Exporting…' : 'Export CSV'}
        </button>
      </form>

      {state.kind === 'loading' && <Loading label="Loading costs…" />}

      {state.kind === 'error' && (
        <EmptyState
          title="Unable to load costs"
          description={state.message}
          action={
            <button type="button" onClick={() => void load()}>
              Retry
            </button>
          }
        />
      )}

      {state.kind === 'ready' && (
        <>
          {state.report.totals.unpriced_count > 0 && (
            <div className="budget-banner budget-banner--warning" role="status">
              {state.report.totals.unpriced_count} call(s) had no configured price and were recorded
              at their provider-reported cost or zero.{' '}
              <Link to="/admin/pricing">Configure pricing →</Link>
            </div>
          )}

          <div className="cost-tiles">
            <div className="cost-tile">
              <span className="cost-tile-label">Total spend</span>
              <span className="cost-tile-value">{money(state.report.totals.estimated_cost)}</span>
            </div>
            <div className="cost-tile">
              <span className="cost-tile-label">Billable calls</span>
              <span className="cost-tile-value">{state.report.totals.count}</span>
            </div>
            <div className="cost-tile">
              <span className="cost-tile-label">Avg / video</span>
              <span className="cost-tile-value">{money(state.report.averages.per_video)}</span>
            </div>
            <div className="cost-tile">
              <span className="cost-tile-label">Avg / project</span>
              <span className="cost-tile-value">{money(state.report.averages.per_project)}</span>
            </div>
          </div>

          <div className="admin-card">
            <h3>Spend by provider</h3>
            <BarRows rows={state.report.by_provider} />
          </div>

          <div className="admin-card">
            <h3>Spend by service</h3>
            <BarRows rows={state.report.by_service} />
          </div>

          <div className="admin-card">
            <h3>Daily spend</h3>
            {state.report.by_day.length === 0 ? (
              <p className="admin-muted">No usage in this range.</p>
            ) : (
              <div className="table-scroll">
                <table className="data-table">
                  <thead>
                    <tr>
                      <th>Day</th>
                      <th>Est. cost</th>
                    </tr>
                  </thead>
                  <tbody>
                    {state.report.by_day.map((row) => (
                      <tr key={row.day}>
                        <td>{row.day}</td>
                        <td>{money(row.estimated_cost)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
            )}
          </div>

          <div className="admin-grid">
            <SpendTable title="Top users by spend" rows={state.users} />
            <SpendTable title="Top projects by spend" rows={state.projects} />
          </div>
        </>
      )}
    </section>
  )
}
