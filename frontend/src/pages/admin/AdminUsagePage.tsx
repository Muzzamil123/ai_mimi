import { useCallback, useEffect, useState } from 'react'
import { getUsage, type UsageData, type UsageServiceSummary } from '../../api/admin'
import { EmptyState } from '../../components/EmptyState'
import { Loading } from '../../components/Loading'
import { getErrorMessage } from '../../lib/errors'

type LoadState =
  | { kind: 'loading' }
  | { kind: 'ready'; data: UsageData }
  | { kind: 'error'; message: string }

function money(value: number): string {
  return `$${value.toFixed(4)}`
}

function ServiceTable({ title, summary }: { title: string; summary: UsageServiceSummary }) {
  const showsTokens = summary.providers.some((p) => p.input_tokens !== undefined)
  return (
    <div className="admin-card">
      <h3>
        {title} <span className="admin-muted">({summary.total_count} calls)</span>
      </h3>
      <p>
        Total estimated cost: <strong>{money(summary.total_estimated_cost)}</strong>
      </p>
      {summary.providers.length === 0 ? (
        <p className="admin-muted">No recorded calls yet.</p>
      ) : (
        <div className="table-scroll">
          <table className="data-table">
            <thead>
              <tr>
                <th>Provider</th>
                <th>Calls</th>
                <th>Est. cost</th>
                {showsTokens && (
                  <>
                    <th>Input tokens</th>
                    <th>Output tokens</th>
                  </>
                )}
              </tr>
            </thead>
            <tbody>
              {summary.providers.map((row) => (
                <tr key={row.provider ?? 'unknown'}>
                  <td>{row.provider ?? 'unknown'}</td>
                  <td>{row.count}</td>
                  <td>{money(row.estimated_cost)}</td>
                  {showsTokens && (
                    <>
                      <td>{row.input_tokens ?? 0}</td>
                      <td>{row.output_tokens ?? 0}</td>
                    </>
                  )}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  )
}

export function AdminUsagePage() {
  const [state, setState] = useState<LoadState>({ kind: 'loading' })

  const load = useCallback(async () => {
    setState({ kind: 'loading' })
    try {
      const data = await getUsage()
      setState({ kind: 'ready', data })
    } catch (err) {
      setState({ kind: 'error', message: getErrorMessage(err, 'Failed to load usage') })
    }
  }, [])

  useEffect(() => {
    void load()
  }, [load])

  if (state.kind === 'loading') return <Loading label="Loading usage…" />
  if (state.kind === 'error') {
    return (
      <EmptyState
        title="Unable to load usage"
        description={state.message}
        action={
          <button type="button" onClick={() => void load()}>
            Retry
          </button>
        }
      />
    )
  }

  return (
    <section className="admin-usage">
      <div className="page-header">
        <h1>Provider usage</h1>
      </div>
      <p className="admin-muted">{state.data.note}</p>
      <div className="admin-grid">
        <ServiceTable title="Character images (Gemini)" summary={state.data.character_generation} />
        <ServiceTable title="Prompts (OpenAI)" summary={state.data.prompt_generation} />
        <ServiceTable title="Videos (Google Labs)" summary={state.data.video_generation} />
      </div>
    </section>
  )
}
