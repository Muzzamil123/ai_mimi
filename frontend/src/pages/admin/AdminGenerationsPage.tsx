import { useCallback, useEffect, useState } from 'react'
import { toast } from 'sonner'
import {
  cancelGeneration,
  listGenerations,
  retryGeneration,
  retryGenerationAsset,
  type AdminListMeta,
} from '../../api/admin'
import type { VideoGeneration, VideoGenerationStatus } from '../../api/videoGenerations'
import { EmptyState } from '../../components/EmptyState'
import { GenerationStatusBadge } from '../../components/GenerationStatusBadge'
import { Loading } from '../../components/Loading'
import { Pagination } from '../../components/Pagination'
import { getErrorMessage } from '../../lib/errors'

type LoadState =
  | { kind: 'loading' }
  | { kind: 'ready'; generations: VideoGeneration[]; meta: AdminListMeta }
  | { kind: 'error'; message: string }

const PER_PAGE = 20

const STATUS_OPTIONS: VideoGenerationStatus[] = [
  'pending',
  'processing',
  'completed',
  'failed',
  'cancelled',
]

export function AdminGenerationsPage() {
  const [state, setState] = useState<LoadState>({ kind: 'loading' })
  const [status, setStatus] = useState<VideoGenerationStatus | ''>('')
  const [page, setPage] = useState(1)
  const [busyId, setBusyId] = useState<number | null>(null)

  const load = useCallback(async () => {
    setState({ kind: 'loading' })
    try {
      const { generations, meta } = await listGenerations({ page, per_page: PER_PAGE, status })
      setState({ kind: 'ready', generations, meta })
    } catch (err) {
      setState({ kind: 'error', message: getErrorMessage(err, 'Failed to load generations') })
    }
  }, [page, status])

  useEffect(() => {
    void load()
  }, [load])

  const act = async (id: number, fn: () => Promise<unknown>, success: string, failure: string) => {
    setBusyId(id)
    try {
      await fn()
      toast.success(success)
      await load()
    } catch (err) {
      toast.error(getErrorMessage(err, failure))
    } finally {
      setBusyId(null)
    }
  }

  return (
    <section className="admin-generations">
      <div className="page-header">
        <h1>Generation jobs</h1>
      </div>

      <form className="admin-filters" onSubmit={(event) => event.preventDefault()}>
        <div className="field">
          <label htmlFor="gen-status">Status</label>
          <select
            id="gen-status"
            value={status}
            onChange={(event) => {
              setPage(1)
              setStatus(event.target.value as VideoGenerationStatus | '')
            }}
          >
            <option value="">All statuses</option>
            {STATUS_OPTIONS.map((option) => (
              <option key={option} value={option}>
                {option}
              </option>
            ))}
          </select>
        </div>
        <button
          type="button"
          onClick={() => {
            setPage(1)
            setStatus('failed')
          }}
        >
          Show failed
        </button>
      </form>

      {state.kind === 'loading' && <Loading label="Loading generations…" />}

      {state.kind === 'error' && (
        <EmptyState
          title="Unable to load generations"
          description={state.message}
          action={
            <button type="button" onClick={() => void load()}>
              Retry
            </button>
          }
        />
      )}

      {state.kind === 'ready' && state.generations.length === 0 && (
        <EmptyState title="No generations" description="No generation jobs match these filters." />
      )}

      {state.kind === 'ready' && state.generations.length > 0 && (
        <>
          <div className="table-scroll">
            <table className="data-table">
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Video</th>
                  <th>Variant</th>
                  <th>Status</th>
                  <th>Attempts</th>
                  <th>Error</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {state.generations.map((generation) => (
                  <tr key={generation.id}>
                    <td>{generation.id}</td>
                    <td>#{generation.video_id}</td>
                    <td>{generation.label}</td>
                    <td>
                      <GenerationStatusBadge status={generation.status} />
                    </td>
                    <td>{generation.attempt_count}</td>
                    <td className="admin-muted">{generation.error_message ?? '—'}</td>
                    <td className="admin-row-actions">
                      {generation.status === 'failed' && (
                        <button
                          type="button"
                          className="link-button"
                          disabled={busyId === generation.id}
                          onClick={() =>
                            void act(
                              generation.id,
                              () => retryGeneration(generation.id),
                              'Variant retried',
                              'Unable to retry variant',
                            )
                          }
                        >
                          Retry
                        </button>
                      )}
                      {generation.status === 'completed' && (
                        <button
                          type="button"
                          className="link-button"
                          disabled={busyId === generation.id}
                          onClick={() =>
                            void act(
                              generation.id,
                              () => retryGenerationAsset(generation.id),
                              'Asset processing restarted',
                              'Unable to retry asset processing',
                            )
                          }
                        >
                          Retry asset
                        </button>
                      )}
                      {(generation.status === 'pending' || generation.status === 'processing') && (
                        <button
                          type="button"
                          className="link-button"
                          disabled={busyId === generation.id}
                          onClick={() =>
                            void act(
                              generation.id,
                              () => cancelGeneration(generation.id),
                              'Generation cancelled',
                              'Unable to cancel generation',
                            )
                          }
                        >
                          Cancel
                        </button>
                      )}
                    </td>
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
