import { useCallback, useEffect, useState } from 'react'
import { toast } from 'sonner'
import { fetchHealth, type HealthResponse } from '../api/health'
import { Loading } from '../components/Loading'
import { EmptyState } from '../components/EmptyState'

type LoadState =
  { kind: 'loading' } | { kind: 'ready'; data: HealthResponse } | { kind: 'error'; message: string }

/** Proves end-to-end connectivity between the React app and the Rails API. */
export function HealthPage() {
  const [state, setState] = useState<LoadState>({ kind: 'loading' })

  const load = useCallback(async () => {
    setState({ kind: 'loading' })
    try {
      const data = await fetchHealth()
      setState({ kind: 'ready', data })
    } catch (err) {
      const message =
        err && typeof err === 'object' && 'message' in err
          ? String((err as { message: unknown }).message)
          : 'Failed to reach the API'
      setState({ kind: 'error', message })
      toast.error(message)
    }
  }, [])

  useEffect(() => {
    void load()
  }, [load])

  if (state.kind === 'loading') {
    return <Loading label="Checking system health…" />
  }

  if (state.kind === 'error') {
    return (
      <EmptyState
        title="API unreachable"
        description={state.message}
        action={
          <button type="button" onClick={() => void load()}>
            Retry
          </button>
        }
      />
    )
  }

  const { data } = state
  return (
    <section className="health">
      <h1>System Health</h1>
      <dl className="health-grid">
        <div>
          <dt>API</dt>
          <dd data-status={data.status === 'ok' ? 'ok' : 'error'}>{data.status}</dd>
        </div>
        <div>
          <dt>Version</dt>
          <dd>{data.version}</dd>
        </div>
        <div>
          <dt>Database</dt>
          <dd data-status={data.components.database}>{data.components.database}</dd>
        </div>
        <div>
          <dt>Redis</dt>
          <dd data-status={data.components.redis}>{data.components.redis}</dd>
        </div>
        <div>
          <dt>Sidekiq</dt>
          <dd data-status={data.components.sidekiq}>{data.components.sidekiq}</dd>
        </div>
      </dl>
      <button type="button" onClick={() => void load()}>
        Refresh
      </button>
    </section>
  )
}
