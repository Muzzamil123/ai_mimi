import { useCallback, useEffect, useState } from 'react'
import { listAuditLogs, type AuditLogEntry, type AdminListMeta } from '../../api/admin'
import { EmptyState } from '../../components/EmptyState'
import { Loading } from '../../components/Loading'
import { Pagination } from '../../components/Pagination'
import { getErrorMessage } from '../../lib/errors'

type LoadState =
  | { kind: 'loading' }
  | { kind: 'ready'; logs: AuditLogEntry[]; meta: AdminListMeta }
  | { kind: 'error'; message: string }

const PER_PAGE = 25

export function AdminAuditLogsPage() {
  const [state, setState] = useState<LoadState>({ kind: 'loading' })
  const [actionInput, setActionInput] = useState('')
  const [resourceInput, setResourceInput] = useState('')
  const [filters, setFilters] = useState<{ action_name?: string; resource_type?: string }>({})
  const [page, setPage] = useState(1)

  const load = useCallback(async () => {
    setState({ kind: 'loading' })
    try {
      const { audit_logs, meta } = await listAuditLogs({ page, per_page: PER_PAGE, ...filters })
      setState({ kind: 'ready', logs: audit_logs, meta })
    } catch (err) {
      setState({ kind: 'error', message: getErrorMessage(err, 'Failed to load audit logs') })
    }
  }, [page, filters])

  useEffect(() => {
    void load()
  }, [load])

  const onSubmit = (event: React.FormEvent) => {
    event.preventDefault()
    setPage(1)
    setFilters({
      action_name: actionInput.trim() || undefined,
      resource_type: resourceInput.trim() || undefined,
    })
  }

  return (
    <section className="admin-audit">
      <div className="page-header">
        <h1>Audit logs</h1>
      </div>

      <form className="admin-filters" onSubmit={onSubmit}>
        <div className="field">
          <label htmlFor="audit-action">Action</label>
          <input
            id="audit-action"
            type="search"
            placeholder="e.g. user.suspend"
            value={actionInput}
            onChange={(event) => setActionInput(event.target.value)}
          />
        </div>
        <div className="field">
          <label htmlFor="audit-resource">Resource type</label>
          <input
            id="audit-resource"
            type="search"
            placeholder="e.g. Project"
            value={resourceInput}
            onChange={(event) => setResourceInput(event.target.value)}
          />
        </div>
        <button type="submit">Filter</button>
      </form>

      {state.kind === 'loading' && <Loading label="Loading audit logs…" />}

      {state.kind === 'error' && (
        <EmptyState
          title="Unable to load audit logs"
          description={state.message}
          action={
            <button type="button" onClick={() => void load()}>
              Retry
            </button>
          }
        />
      )}

      {state.kind === 'ready' && state.logs.length === 0 && (
        <EmptyState title="No audit entries" description="No entries match these filters." />
      )}

      {state.kind === 'ready' && state.logs.length > 0 && (
        <>
          <div className="table-scroll">
            <table className="data-table">
              <thead>
                <tr>
                  <th>When</th>
                  <th>Actor</th>
                  <th>Action</th>
                  <th>Resource</th>
                  <th>Metadata</th>
                  <th>IP</th>
                </tr>
              </thead>
              <tbody>
                {state.logs.map((log) => (
                  <tr key={log.id}>
                    <td>{new Date(log.created_at).toLocaleString()}</td>
                    <td>{log.actor_label ?? (log.actor_id ? `#${log.actor_id}` : 'system')}</td>
                    <td>{log.action}</td>
                    <td>
                      {log.resource_type
                        ? `${log.resource_type}${log.resource_id ? ` #${log.resource_id}` : ''}`
                        : '—'}
                    </td>
                    <td>
                      <code className="admin-metadata">{JSON.stringify(log.metadata)}</code>
                    </td>
                    <td className="admin-muted">{log.ip_address ?? '—'}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <Pagination meta={state.meta} onPageChange={setPage} />
        </>
      )}
    </section>
  )
}
