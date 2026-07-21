import { useCallback, useEffect, useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { toast } from 'sonner'
import { listVideos, retryPrompt, type AdminListMeta } from '../../api/admin'
import type { Video, VideoStatus } from '../../api/videos'
import { EmptyState } from '../../components/EmptyState'
import { Loading } from '../../components/Loading'
import { Pagination } from '../../components/Pagination'
import { VideoStatusBadge } from '../../components/VideoStatusBadge'
import { getErrorMessage } from '../../lib/errors'

type LoadState =
  | { kind: 'loading' }
  | { kind: 'ready'; videos: Video[]; meta: AdminListMeta }
  | { kind: 'error'; message: string }

const PER_PAGE = 20

const STATUS_OPTIONS: VideoStatus[] = [
  'draft',
  'transcribing',
  'idea_ready',
  'generating_prompt',
  'prompt_ready',
  'queued',
  'generating',
  'partially_completed',
  'completed',
  'failed',
  'cancelled',
]

const PROMPT_RETRYABLE: VideoStatus[] = ['idea_ready', 'prompt_ready', 'failed']

export function AdminVideosPage() {
  const [searchParams] = useSearchParams()
  const projectFilter = searchParams.get('project_id')
  const [state, setState] = useState<LoadState>({ kind: 'loading' })
  const [status, setStatus] = useState<VideoStatus | ''>('')
  const [page, setPage] = useState(1)
  const [busyId, setBusyId] = useState<number | null>(null)

  const load = useCallback(async () => {
    setState({ kind: 'loading' })
    try {
      const { videos, meta } = await listVideos({
        page,
        per_page: PER_PAGE,
        status,
        project_id: projectFilter ? Number(projectFilter) : undefined,
      })
      setState({ kind: 'ready', videos, meta })
    } catch (err) {
      setState({ kind: 'error', message: getErrorMessage(err, 'Failed to load videos') })
    }
  }, [page, status, projectFilter])

  useEffect(() => {
    void load()
  }, [load])

  const onRetryPrompt = async (video: Video) => {
    setBusyId(video.id)
    try {
      await retryPrompt(video.id)
      toast.success('Prompt generation restarted')
      await load()
    } catch (err) {
      toast.error(getErrorMessage(err, 'Unable to retry prompt generation'))
    } finally {
      setBusyId(null)
    }
  }

  return (
    <section className="admin-videos">
      <div className="page-header">
        <h1>Videos{projectFilter && <span className="admin-muted"> · project #{projectFilter}</span>}</h1>
      </div>

      <form className="admin-filters" onSubmit={(event) => event.preventDefault()}>
        <div className="field">
          <label htmlFor="video-status">Status</label>
          <select
            id="video-status"
            value={status}
            onChange={(event) => {
              setPage(1)
              setStatus(event.target.value as VideoStatus | '')
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
      </form>

      {state.kind === 'loading' && <Loading label="Loading videos…" />}

      {state.kind === 'error' && (
        <EmptyState
          title="Unable to load videos"
          description={state.message}
          action={
            <button type="button" onClick={() => void load()}>
              Retry
            </button>
          }
        />
      )}

      {state.kind === 'ready' && state.videos.length === 0 && (
        <EmptyState title="No videos" description="No videos match these filters." />
      )}

      {state.kind === 'ready' && state.videos.length > 0 && (
        <>
          <div className="table-scroll">
            <table className="data-table">
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Title</th>
                  <th>Project</th>
                  <th>Status</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {state.videos.map((video) => (
                  <tr key={video.id}>
                    <td>{video.id}</td>
                    <td>{video.title}</td>
                    <td>
                      <Link to={`/admin/projects/${video.project_id}`}>#{video.project_id}</Link>
                    </td>
                    <td>
                      <VideoStatusBadge status={video.status} />
                    </td>
                    <td>
                      {PROMPT_RETRYABLE.includes(video.status) && video.idea_present && (
                        <button
                          type="button"
                          className="link-button"
                          disabled={busyId === video.id}
                          onClick={() => void onRetryPrompt(video)}
                        >
                          Retry prompt
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
